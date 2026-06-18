class_name WanderProcessors
extends RefCounted

# ==============================================================================
# 【云游寻宝事务处理器集合】
# 实现了 NPC 外出寻宝的三层流转：需求初审 -> 风险环境 -> 收益结算
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 需求与寿命初审处理器 (Need Processor)
# ------------------------------------------------------------------------------
class NeedProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc_data = _get_npc(ticket.initiator_id)
		if not npc_data: return Result.REJECT
		
		# 初审：如果寿命不足 5 年，直接否决，必须闭关续命
		var remaining_life = npc_data.max_lifespan - npc_data.age
		if remaining_life < 5.0:
			ticket.context["reject_reason"] = "寿元将尽，不敢外出"
			return Result.REJECT
			
		# 如果疗伤需求极高，也不外出，暂缓搁置
		if npc_data.need_healing > 80.0:
			return Result.SUSPEND
			
		return Result.PASS

# ------------------------------------------------------------------------------
# 2. 环境风险处理器 (Risk Processor)
# ------------------------------------------------------------------------------
class RiskProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc_data = _get_npc(ticket.initiator_id)
		if not npc_data: return Result.REJECT
		
		var roll = randf()
		# 10% 的概率遭遇极端妖兽
		if roll < 0.10:
			# 苟道中人直接逃避
			if npc_data.get_meta("trait_coward", false):
				ticket.context["reject_reason"] = "遭遇大妖，立刻逃跑"
				return Result.REJECT
			else:
				# 正常人硬刚，可能受伤
				ticket.context["took_damage"] = 40.0
		
		return Result.PASS

# ------------------------------------------------------------------------------
# 3. 终态收益结算 (Reward Processor)
# ------------------------------------------------------------------------------
class RewardProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		# 这一层消耗时间
		var time_needed = 1.0 # 假设一次云游需要 1 年
		if ticket.time_spent_so_far < time_needed:
			ticket.time_spent_so_far += time_delta
			return Result.SUSPEND # 时间还没花够，继续挂起，等下个分片
			
		var npc_data = _get_npc(ticket.initiator_id)
		if not npc_data: return Result.REJECT
		
		# 开始结算
		var roll = randf()
		if roll < 0.2:
			ticket.context["reward"] = "极品灵石"
		else:
			ticket.context["reward"] = "一无所获"
			
		return Result.PASS
		
	func on_callback(ticket: TransactionTicket, is_success: bool) -> void:
		var npc = _get_npc(ticket.initiator_id)
		if not npc: return
		
		if not is_success:
			var reason = ticket.context.get("reject_reason", "未知原因")
			# 发送失败回执或直接改变状态
			npc.need_healing += 10.0 # 失败挫败感
		else:
			var dmg = ticket.context.get("took_damage", 0.0)
			var reward = ticket.context.get("reward", "")
			
			npc.stamina -= dmg
			if reward == "极品灵石":
				npc.money += 5000
				
			npc.need_cultivation = max(0.0, npc.need_cultivation - 20)
