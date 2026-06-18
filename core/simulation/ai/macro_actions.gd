extends Node
class_name MacroActions

# ==============================================================================
# 【宏观动作执行库 (MacroActions) - 大块时间阻断版】
# ==============================================================================

static func _log_history(npc: CharacterData, msg: String, level: int = 1) -> void:
	npc.history_trajectory.append({"age": npc.age, "text": msg, "level": level})
	if npc.history_trajectory.size() > 50:
		npc.history_trajectory.pop_front()
	
	if Engine.get_main_loop().root.has_node("MacroSimulator"):
		var ms = Engine.get_main_loop().root.get_node("MacroSimulator")
		# Check if log level is sufficient for broadcast
		if level >= ms.broadcast_level:
			if ms.has_signal("macro_event_logged"):
				var entry = "[骨龄%d岁] %s" % [npc.age, msg]
				ms.macro_event_logged.emit("【%s】 %s" % [npc.npc_name, entry])

# 执行动作，返回实际消耗的年数
static func execute_action(npc: CharacterData, action_dict: Dictionary, time_left_years: float) -> float:
	var action_name = action_dict.get("name", "无所事事")
	
	match action_name:
		"闭关修炼":
			return _execute_cultivate(npc, time_left_years)
		"疗伤":
			return _execute_heal(npc, time_left_years)
		"杀人越货":
			return _execute_rob(npc, time_left_years)
		"寻找延寿丹":
			return _execute_seek_lifespan(npc, time_left_years)
		"采集灵草":
			return _execute_gather(npc, time_left_years)
		"坊市交易":
			return _execute_trade(npc, time_left_years)
		"社交结网":
			return _execute_social(npc, time_left_years)
		"云游闲逛":
			return _execute_wander(npc, time_left_years)
		_:
			# 无法识别的动作，消耗极少时间跳过
			return min(time_left_years, 0.1)

static func _execute_wander(npc: CharacterData, time_left_years: float) -> float:
	var time_spent = min(randf_range(0.5, 2.0), time_left_years)
	
	# 【大世界事务链】发起事务单据
	var processors: Array[StepProcessor] = [
		WanderProcessors.NeedProcessor.new(),
		WanderProcessors.RiskProcessor.new(),
		WanderProcessors.RewardProcessor.new()
	]
	var ticket = TransactionTicket.new(npc.npc_id, "wander", processors)
	
	if Engine.get_main_loop().root.has_node("TransactionManager"):
		Engine.get_main_loop().root.get_node("TransactionManager").submit_ticket(ticket)
		
	# 假定挂起或处理都需要占用时间
	return time_spent

static func _execute_cultivate(npc: CharacterData, time_left_years: float) -> float:
	var processors: Array[StepProcessor] = [
		CultivateProcessors.EnvProcessor.new(),
		CultivateProcessors.BreakthroughProcessor.new(),
		CultivateProcessors.GrowthProcessor.new()
	]
	var ticket = TransactionTicket.new(npc.npc_id, "cultivate", processors)
	
	if Engine.get_main_loop().root.has_node("TransactionManager"):
		Engine.get_main_loop().root.get_node("TransactionManager").submit_ticket(ticket)
		
	# 假定无论如何，进入一次闭关至少分配并占用一段基础切片时间
	return min(time_left_years, 0.5)

static func _execute_heal(npc: CharacterData, time_left_years: float) -> float:
	# 疗伤耗时约 1-3 年
	var time_spent = min(randf_range(1.0, 3.0), time_left_years)
	npc.stamina = 100
	npc.need_healing = 0.0
	_log_history(npc, "隐姓埋名疗伤 %.1f 年，伤势尽数恢复。" % time_spent)
	return time_spent

static func _execute_rob(npc: CharacterData, time_left_years: float) -> float:
	# 抢劫耗时短，算作 0.5 年（包含寻路踩点）
	var time_spent = min(0.5, time_left_years)
	
	var sm = Engine.get_main_loop().root.get_node_or_null("/root/SocialManager")
	if not sm: return time_spent
	
	var nearby = sm.get_entities_in_radius(npc.current_world_pos, 500.0, "npc")
	var targets = []
	for n in nearby:
		if n.npc_id != npc.npc_id and n.is_alive: targets.append(n)
			
	if targets.is_empty():
		_log_history(npc, "四处游荡大半年，未能找到合适的劫杀目标。")
		npc.need_resource -= 10.0 # 稍微缓解下冲动
		return time_spent
		
	var victim = targets.pick_random()
	if npc.combat_power > victim.combat_power:
		var stolen = int(victim.money * 0.8)
		victim.money -= stolen
		npc.money += stolen
		_log_history(npc, "劫杀了【%s】，夺得 %d 灵石！" % [victim.npc_name, stolen])
		TraitFilter.process_life_event(victim, "robbed")
		TraitFilter.process_life_event(victim, "injured", {"severity": 80.0})
		npc.need_resource = 0.0 # 需求满足
	else:
		_log_history(npc, "试图劫杀【%s】，反被重创！" % victim.npc_name)
		TraitFilter.process_life_event(npc, "injured", {"severity": 60.0})
		
	return time_spent

static func _execute_gather(npc: CharacterData, time_left_years: float) -> float:
	var time_spent = min(1.0, time_left_years)
	npc.money += randi_range(50, 150)
	npc.need_resource -= 20.0
	_log_history(npc, "在深山老林中采集灵草 %d 年，赚取了些许灵石。" % int(time_spent))
	return time_spent

static func _execute_trade(npc: CharacterData, time_left_years: float) -> float:
	var market_pos = Vector3.ZERO # 暂定全局大坊市在原点
	var dist = npc.current_world_pos.distance_to(market_pos)
	
	# 1. 赶路逻辑：跳跃式时间结算与坐标投射
	if dist > 10.0:
		var travel_time = dist * 0.001 # 简单比例：距离 1000 需要 1 年
		if travel_time >= time_left_years:
			# 时间不够走到坊市，只走一半
			npc.current_world_pos = npc.current_world_pos.lerp(market_pos, time_left_years / travel_time)
			_log_history(npc, "正马不停蹄赶往坊市途中...")
			return time_left_years
		else:
			# 刚好走到坊市
			npc.current_world_pos = market_pos
			_log_history(npc, "跋山涉水 %.1f 年，终于抵达了修仙界中心坊市。" % travel_time)
			return travel_time
			
	# 2. 闭环交易逻辑：如果已经在坊市了，开始找人交易（耗时极短 0.1 年）
	var time_spent = min(0.1, time_left_years)
	
	var sm = Engine.get_main_loop().root.get_node_or_null("/root/SocialManager")
	if not sm: return time_spent
	
	var targets = []
	for other in sm.npc_attributes.values():
		if other.npc_id != npc.npc_id and other.is_alive and other.current_world_pos.distance_to(npc.current_world_pos) < 10.0:
			targets.append(other)
			
	if targets.is_empty():
		_log_history(npc, "在坊市苦等旬月，却发现空无一人，无奈离去。")
		npc.need_resource -= 5.0
		return time_spent
		
	# 寻找愿意卖的人（背包有东西）
	var seller = null
	var item_to_buy = ""
	for t in targets:
		if not t.inventory.is_empty():
			seller = t
			item_to_buy = t.inventory.keys()[0] # 随便买他背包第一个东西
			break
			
	if seller and npc.money >= 500:
		npc.money -= 500
		seller.money += 500
		
		seller.inventory[item_to_buy] -= 1
		if seller.inventory[item_to_buy] <= 0:
			seller.inventory.erase(item_to_buy)
			
		npc.inventory[item_to_buy] = npc.inventory.get(item_to_buy, 0) + 1
		
		_log_history(npc, "在坊市巧遇【%s】，花费 500 灵石购得【%s】！" % [seller.npc_name, item_to_buy])
		npc.need_resource = 0.0
		
		# 3. 强联机检测：看看玩家在不在附近
		_check_player_interaction(npc, item_to_buy)
	else:
		_log_history(npc, "囊中羞涩或未寻得宝物，只能在坊市空手而归。")
		npc.need_resource -= 5.0 # 稍微缓解下
		
	return time_spent

static func _check_player_interaction(npc: CharacterData, item: String) -> void:
	var player = Engine.get_main_loop().root.get_tree().get_first_node_in_group("player")
	if not player: return
	
	# 如果玩家跟这笔交易在同一个地块 (相距不足 100米)
	if player.global_position.distance_to(npc.current_world_pos) < 100.0:
		var msg = ""
		if npc.trait_greed > 70:
			msg = "【私聊】[%s]: 小子，把你身上的灵石全交出来，本座留你全尸！" % npc.npc_name
		else:
			msg = "【私聊】[%s]: 这位道友，我观你气宇轩昂，可有多余的【%s】出售？我愿出 500 灵石！" % [npc.npc_name, item]
			
		var ms = Engine.get_main_loop().root.get_node_or_null("/root/MacroSimulator")
		if ms and ms.has_signal("macro_event_logged"):
			ms.macro_event_logged.emit(msg)

static func _execute_seek_lifespan(npc: CharacterData, time_left_years: float) -> float:
	var time_spent = min(5.0, time_left_years)
	if npc.money > 1000 or npc.trait_ambition > 80:
		npc.max_lifespan += 20
		npc.need_lifespan = 0.0
		npc.money -= 1000
		_log_history(npc, "散尽千金/历经九死一生，终于觅得延寿丹，增寿 20 载！")
	else:
		_log_history(npc, "苦寻延寿之法 %d 载，却一无所获，心生绝望。" % int(time_spent))
	return time_spent

static func _execute_social(npc: CharacterData, time_left_years: float) -> float:
	var time_spent = min(1.0, time_left_years)
	npc.need_status -= 30.0
	_log_history(npc, "四处游历，结交道友，名望略有提升。")
	return time_spent
