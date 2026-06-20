extends ChronosAction

func _init() -> void:
	action_id = "breakthrough"
	action_name = "闭关突破"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	var comp = actor.data.cultivation_comp
	return comp.current_qi >= comp.max_qi_cache

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	# 突破是一个一次性结算或者短时间的强判定。
	# 我们在这里模拟：一旦开始突破，花费几天时间后出结果
	var days = hours_passed / 24.0
	
	# 这里简化处理：每过一段时间就尝试一次突破
	var comp = actor.data.cultivation_comp
	if comp.current_qi < comp.max_qi_cache:
		return # 灵气不够，无法突破
		
	# 调用底层突破逻辑
	var success = comp.ascend_realm()
	
	if success:
		var exact_realm = comp.get_realm_name()
		log_event(actor, "历经百般磨难，终于突破成功！当前境界跃升至：【%s】" % exact_realm)
		actor.data.need_cultivation = 0.0
		# 突破成功，寿元增加，气血回满
		actor.data.stamina = 100
		actor.data.mana = 100
	else:
		# 突破失败处理
		log_event(actor, "突破失败！遭到天地灵气反噬，身受重伤，修为大损。")
		actor.data.need_healing += 80.0
		actor.data.stamina /= 2
		# 强行打断当前突破状态
		actor.data.current_action = "heal"
