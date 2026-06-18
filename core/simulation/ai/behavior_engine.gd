class_name BehaviorEngine
extends RefCounted

static func evaluate_next_action(npc: CharacterData) -> String:
	# 1. 绝对高优先级干预
	if npc.max_lifespan - npc.age <= 10:
		return _start_action(npc, "寻延寿丹/强行突破", 60, "野外秘境", "寿元将尽，破釜沉舟外出寻找机缘或强行突破！")
		
	var hp_percent = npc.needs.get("safety", 100.0) / 100.0
	if hp_percent < 0.3:
		return _start_action(npc, "闭关疗伤", 30, "宗门洞府", "身受重伤，闭门不出，苦苦疗伤。")
		
	# 检查宗门任务
	if not npc.current_mission.is_empty():
		var req_cp = npc.current_mission.get("required_cp", 0)
		if npc.combat_power < req_cp:
			return _start_action(npc, "战前整备", 15, "主城坊市", "任务艰险，前往坊市重金求购物资以提升战力。")
		else:
			return _start_action(npc, "执行任务", 20, "野外秘境", "奉命行事，正在执行宗门分派的任务。")
			
	# 2. 确立当前核心需求 (Need Targeting)
	var target_need = ""
	var max_gap = -1.0
	for key in npc.needs.keys():
		var gap = 100.0 - npc.needs[key]
		if gap > max_gap:
			max_gap = gap
			target_need = key
			
	# 如果所有需求都几乎满了，默认去修炼
	if max_gap < 10.0:
		target_need = "cultivation"
		
	# 3. 追求单位时间收益最大化 (Maximize Yield / Time)
	var best_action = ""
	var best_yield_per_day = -999.0
	var chosen_days = 10
	var chosen_loc = ""
	var chosen_desc = ""
	var chosen_satisfaction = {}
	
	# 生成与 NPC 自身属性挂钩的动态行为表
	var available_actions = _get_dynamic_actions(npc)
	
	for action in available_actions:
		# 只看能满足目标需求的行为
		if action.satisfaction.has(target_need) and action.satisfaction[target_need] > 0:
			var yield_per_day = action.satisfaction[target_need] / float(action.days)
			if yield_per_day > best_yield_per_day:
				best_yield_per_day = yield_per_day
				best_action = action.name
				chosen_days = action.days
				chosen_loc = action.location
				chosen_desc = action.desc
				chosen_satisfaction = action.satisfaction
				
	# 兜底行为
	if best_action == "":
		best_action = "打坐冥想"
		chosen_days = 3
		chosen_loc = "宗门洞府"
		chosen_desc = "漫无目的地打坐冥想。"
		chosen_satisfaction = {"cultivation": 3.0}
		
	# 行动开始时，预支满足感（防止锁定期间需求卡死）
	for k in chosen_satisfaction.keys():
		npc.needs[k] = clamp(npc.needs.get(k, 100.0) + chosen_satisfaction[k], 0.0, 100.0)
		
	return _start_action(npc, best_action, chosen_days, chosen_loc, chosen_desc)

static func _get_dynamic_actions(npc: CharacterData) -> Array:
	# 将面板属性转化为效率乘区
	var cp_mult = max(0.1, npc.combat_power / 10.0)
	var alc_mult = max(0.1, npc.skill_alchemy / 10.0)
	var charm_mult = max(0.1, npc.charm / 10.0)
	
	return [
		{
			"name": "闭关修炼",
			"days": 30,
			"location": "宗门洞府",
			"desc": "闭关吸纳天地灵气，效率稳定。",
			"satisfaction": {"cultivation": 60.0, "social": -10.0}
		},
		{
			"name": "外出打猎",
			"days": 10,
			"location": "野外秘境",
			"desc": "猎杀妖兽赚取灵石，危险与机遇并存。",
			"satisfaction": {"wealth": 30.0 * cp_mult, "safety": -10.0}
		},
		{
			"name": "坊市炼丹",
			"days": 15,
			"location": "主城坊市",
			"desc": "在坊市炼制定型丹药出售，安全赚取灵石。",
			"satisfaction": {"wealth": 25.0 * alc_mult}
		},
		{
			"name": "坊市社交",
			"days": 5,
			"location": "主城坊市",
			"desc": "结交道友，论道交流。",
			"satisfaction": {"social": 40.0 * charm_mult, "wealth": 5.0 * charm_mult}
		},
		{
			"name": "生死试炼",
			"days": 20,
			"location": "野外秘境",
			"desc": "游走在生死边缘的极端修炼。",
			"satisfaction": {"cultivation": 90.0 * cp_mult, "safety": -30.0}
		}
	]

static func _start_action(npc: CharacterData, action_name: String, days: int, target_location: String, log_msg: String) -> String:
	npc.current_action = action_name
	npc.current_location = target_location
	npc.locked_days_remaining = days
	
	var dm = Engine.get_main_loop().root.get_node_or_null("TimeManager")
	var time_str = dm.get_formatted_time_string() if dm else "Day 0"
	var formatted_log = "[%s] %s" % [time_str, log_msg]
	
	npc.history_trajectory.append(formatted_log)
	if npc.history_trajectory.size() > 50:
		npc.history_trajectory.pop_front()
		
	return "[color=cyan]%s[/color] 开始执行 [b]%s[/b] (耗时 %d 天)\n    [color=gray]%s[/color]" % [npc.npc_name, action_name, days, log_msg]
