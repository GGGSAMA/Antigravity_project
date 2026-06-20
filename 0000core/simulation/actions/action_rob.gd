extends ChronosAction

func _init() -> void:
	action_id = "rob"
	action_name = "杀人夺宝"
	is_long_term = false

func can_execute(actor: ActorProxy) -> bool:
	# 需要资源且本身性格偏邪恶
	return actor.data.need_resource > 20.0 and actor.data.trait_morality < 40

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	# 打劫是一个短时行为，这里简化为：一旦被选中执行，就寻找一个受害者
	var days = hours_passed / 24.0
	
	var sm = Engine.get_main_loop().root.get_node_or_null("SocialManager")
	if not sm: return
	
	# 寻找同一个区域的随机弱者
	var possible_victims = []
	for npc_id in sm.npc_attributes.keys():
		var victim = sm.npc_attributes[npc_id]
		if victim.npc_id == actor.data.npc_id: continue
		if not victim.is_alive: continue
		if victim.current_world_pos.distance_to(actor.data.current_world_pos) < 1000.0:
			possible_victims.append(victim)
			
	if possible_victims.is_empty():
		actor.data.need_resource -= days * 2.0 # 没找到人，降一点需求防卡死
		return
		
	var target = possible_victims[randi() % possible_victims.size()]
	
	# 战力比拼
	if actor.data.combat_power > target.combat_power:
		# 打劫成功
		var stolen = int(target.money * randf_range(0.2, 0.5))
		target.money -= stolen
		actor.data.money += stolen
		
		# 增加业力
		actor.data.karma -= 50
		actor.data.fame -= 20
		actor.data.need_resource = 0.0
		
		# 结仇
		if not target.enemies.has(actor.data.npc_id):
			target.enemies.append(actor.data.npc_id)
			
		log_event(actor, "在野外埋伏，成功劫掠了【%s】，夺得灵石 %d 枚，惹下一笔业障！" % [target.npc_name, stolen])
		
		# 被害者的日志
		var target_proxy = ActorProxy.new(target)
		var v_log = load("res://0000core/simulation/actions/chronos_action.gd").new()
		v_log.log_event(target_proxy, "外出时遭遇歹人【%s】袭击，不敌被抢去灵石 %d 枚，此仇必报！" % [actor.data.npc_name, stolen])
	else:
		# 打劫失败
		actor.data.stamina -= randi_range(30, 80)
		actor.data.need_healing += 50.0
		var lost = int(actor.data.money * randf_range(0.1, 0.3))
		actor.data.money -= lost
		target.money += lost
		actor.data.karma -= 20
		
		log_event(actor, "试图打劫【%s】，却不料踢到了铁板，被打成重伤，甚至还倒赔了 %d 灵石买命！" % [target.npc_name, lost])
		
		# 结仇 (受害者可能也记仇)
		if not target.enemies.has(actor.data.npc_id):
			target.enemies.append(actor.data.npc_id)
			
		var target_proxy = ActorProxy.new(target)
		var v_log = load("res://0000core/simulation/actions/chronos_action.gd").new()
		v_log.log_event(target_proxy, "遭遇不知死活的散修【%s】劫道，将其重创并反抢了 %d 灵石。" % [actor.data.npc_name, lost])
