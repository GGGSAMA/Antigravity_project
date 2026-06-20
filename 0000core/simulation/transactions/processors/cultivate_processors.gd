class_name CultivateProcessors
extends RefCounted

# ==============================================================================
# 【提升修为事务处理器集合】
# 实现了 NPC 闭关修炼的三层流转：环境风水 -> 瓶颈天劫 -> 收益结算
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 环境与风水校验器 (Environment Processor)
# ------------------------------------------------------------------------------
class EnvProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc_data = _get_npc(ticket.initiator_id)
		if not npc_data: return Result.REJECT
		
		var aura_multiplier = 1.0
		
		# 听从架构师指示：移除所有“空间格子灵气”的弱耦合判定！
		# 修为完全取决于角色自身的资质、灵根等内部属性。
		# 仅在此处保留【全局天道法则】的接口（如开启末法时代，才会有大势干扰）
		if Engine.get_main_loop().root.has_node("GlobalModifierDispatcher"):
			var global_mod = Engine.get_main_loop().root.get_node("GlobalModifierDispatcher")
			aura_multiplier *= global_mod.get_modifier("world_aura_density", 1.0)
			
		ticket.context["aura_multiplier"] = aura_multiplier
		return Result.PASS

# ------------------------------------------------------------------------------
# 2. 瓶颈与天劫处理器 (Breakthrough Processor)
# ------------------------------------------------------------------------------
class BreakthroughProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc_data = _get_npc(ticket.initiator_id)
		if not npc_data or not npc_data.cultivation_comp: return Result.REJECT
		
		if not npc_data.cultivation_comp.is_bottlenecked:
			# 不在瓶颈期，直接放行，进入普通修为增长层
			return Result.PASS
			
		# 听从架构师指示：突破时间由组件里暴露的参数算出，供 Inspector 界面调节权重
		var current_realm = npc_data.cultivation_comp.cultivation_realm
		var base_time = npc_data.cultivation_comp.base_breakthrough_time_years
		var mult = npc_data.cultivation_comp.realm_time_multiplier
		var time_needed = base_time * pow(mult, current_realm - 1.0)
		
		# 【未来扩展预留】：可以乘以性格系数。例如 懒散性格 (diligence=0.5) 则所需时间更长。
		# if npc_data.has("diligence"):
		#     time_needed *= (2.0 - npc_data.diligence) 
		
		if ticket.time_spent_so_far < time_needed:
			ticket.time_spent_so_far += time_delta
			ticket.bind_state("冲击瓶颈中...")
			return Result.SUSPEND # 时间未满，搁置事务
			
		# 突破结算
		var success = npc_data.cultivation_comp.attempt_breakthrough(false, 0.0)
		if success:
			ticket.context["breakthrough"] = "success"
			ticket.context["new_realm"] = npc_data.cultivation_comp.get_realm_name()
			return Result.PASS
		else:
			ticket.context["breakthrough"] = "failed"
			return Result.REJECT # 突破失败，直接中途否决！

	# 双向反馈链路：如果这层被拒绝（突破失败），或者成功了，在这里统一发回执
	func on_callback(ticket: TransactionTicket, is_success: bool) -> void:
		var npc = _get_npc(ticket.initiator_id)
		if not npc: return
		
		var bt_status = ticket.context.get("breakthrough", "")
		if bt_status == "success":
			if Engine.get_main_loop().root.has_node("EventBus"):
				Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(npc, "breakthrough_success", {"realm": ticket.context["new_realm"]})
			TraitFilter.process_life_event(npc, "breakthrough_success")
			
			# 【未来扩展预留】：结合性格系数调整心理需求
			# var diligence = npc.get("diligence") if npc.has("diligence") else 1.0
			npc.need_status += 30.0 # 刚突破想出去炫耀
			npc.need_cultivation = max(0.0, npc.need_cultivation - 50.0) # 倦怠期，未来可用 50.0 * (2.0 - diligence) 动态计算
			
		elif bt_status == "failed":
			if Engine.get_main_loop().root.has_node("EventBus"):
				Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(npc, "breakthrough_fail")
			TraitFilter.process_life_event(npc, "breakthrough_failed")
			# 突破失败，直接走双向反馈链路回滚并惩罚
			npc.stamina = max(1, npc.stamina - 50) 
			npc.need_healing += 60.0

# ------------------------------------------------------------------------------
# 3. 长线修为增长结算器 (Growth Processor)
# ------------------------------------------------------------------------------
class GrowthProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		# 只有没有卡在瓶颈的人才会流转到这里
		var npc_data = _get_npc(ticket.initiator_id)
		if not npc_data or not npc_data.cultivation_comp: return Result.REJECT
		
		# 同样使用组件上的权重配置
		var base_speed = npc_data.cultivation_comp.base_cultivation_speed
		
		var time_needed = 0.5 
		if ticket.time_spent_so_far < time_needed:
			ticket.time_spent_so_far += time_delta
			# 在等待期间，预先加一部分修为，分段状态机体现
			var aura = ticket.context.get("aura_multiplier", 1.0)
			
			# 【未来扩展预留】：可以乘上 NPC 的 diligence 性格权重
			# 比如 diligence=1.5 的卷王，每次切片多拿 50% 经验
			var xp_gained = (base_speed * aura * float(npc_data.aptitude) / 50.0) * time_delta
			npc_data.cultivation_comp.add_qi(xp_gained)
			npc_data.need_cultivation = max(0.0, npc_data.need_cultivation - 10.0 * time_delta)
			
			return Result.SUSPEND # 搁置，下次继续给点修为
			
		# 如果时间满了，结束这次闭关事务
		return Result.PASS


