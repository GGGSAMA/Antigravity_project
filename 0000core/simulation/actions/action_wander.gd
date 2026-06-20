extends ChronosAction

func _init() -> void:
	action_id = "wander"
	action_name = "云游闲逛"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return true 

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0 # 由 UtilityBrain 接管

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var days = hours_passed / 24.0
	
	# 以天为单位触发随机事件
	for i in range(int(days)):
		_roll_daily_event(actor)
		
	# 满足了一定的需求 (作为兜底行为，略微降低资源需求)
	actor.add_stat("need_resource", -days * 0.2)
	actor.add_stat("need_status", -days * 0.1)

func _roll_daily_event(actor: ActorProxy) -> void:
	var r = randf()
	if r < 0.60:
		# 平安无事
		pass
	elif r < 0.80:
		# 找到小资源
		var realm = actor.data.cultivation_comp.cultivation_realm
		var found_money = randi_range(10, 50) * realm
		actor.data.money += found_money
		if randf() < 0.1: # 偶尔记录一次
			log_event(actor, "在野外偶然发现一株灵草，卖得 %d 灵石。" % found_money)
	elif r < 0.90:
		# 战斗遭遇
		actor.data.stamina -= randi_range(5, 20)
		actor.data.cultivation_comp.add_qi(randf_range(10.0, 50.0))
		actor.data.need_healing += randf_range(5.0, 15.0)
		if randf() < 0.1:
			log_event(actor, "遭遇野生妖兽袭击，历经一番苦战将其击杀，受了些轻伤。")
	else:
		# 奇遇或发现
		if randf() < 0.1:
			log_event(actor, "误入一处上古修士遗留的洞府外围，虽然未能深入，但也略有所悟。")
			actor.data.need_cultivation += 20.0 # 激发了修炼欲望
