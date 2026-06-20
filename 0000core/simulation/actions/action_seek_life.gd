extends ChronosAction

func _init() -> void:
	action_id = "seek_life"
	action_name = "寻找延寿丹"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return true 

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0 # 由 UtilityBrain 接管

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var days = hours_passed / 24.0
	
	# 暂时作为【闲逛/历练找机缘】的通用结果
	if actor.is_player or days >= 30:
		log_event(actor, "花费了 %.1f 天时间外出历练寻找机缘（%s）。" % [days, action_name])
		
	# 历练机缘：稍微降低一点资源需求，或者概率得到点小东西（这里做极简处理）
	actor.add_stat("need_resource", -days * 0.5)
	actor.add_stat("need_status", -days * 0.5)
