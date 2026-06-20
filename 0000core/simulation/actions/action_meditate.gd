extends ChronosAction

func _init() -> void:
	action_id = "meditate"
	action_name = "吐纳闭关"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return true # 随时可以打坐

func evaluate_utility(actor: ActorProxy) -> float:
	# NPC AI 逻辑：如果修炼需求高，则打坐意愿高
	var need = actor.get_stat("need_cultivation")
	if need != null:
		return need
	return 50.0

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var days = hours_passed / 24.0
	
	# 获取基础属性
	var aptitude = actor.get_stat("aptitude")
	if aptitude == null: aptitude = 10
	
	var base_qi_regen = 100.0
	var qi_amount = int(base_qi_regen * days * (1.0 + float(aptitude) * 0.05))
	
	# 判断是否瓶颈
	var is_bottlenecked = actor.get_stat("is_bottlenecked")
	if is_bottlenecked:
		var success = actor.attempt_breakthrough()
		var msg = ""
		if success:
			msg = "闭关苦修 %.1f 天，厚积薄发，成功突破了境界！" % days
		else:
			msg = "闭关苦修 %.1f 天，尝试突破失败，根基受损。" % days
		if actor.is_player or days >= 180:
			log_event(actor, msg)
	else:
		# 增加修为
		actor.add_stat("current_qi", float(qi_amount))
		
		# 记入史书或履历
		var msg = "闭关苦修 %.1f 天，修为精进了 %d 点。" % [days, qi_amount]
		if actor.is_player:
			log_event(actor, msg)
		else:
			# 对于 NPC，如果跳跃时间较长（例如超过半年），则在履历里记一笔
			if days >= 180:
				log_event(actor, msg)
