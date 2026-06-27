extends ChronosAction

func _init() -> void:
	action_id = "heal"
	action_name = "打坐疗伤"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return actor.data.need_healing > 0.0

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var days = hours_passed / 24.0

	# 疗伤消耗灵石或丹药加速，这里简化为如果有钱就消耗钱换血
	var base_heal = days * 10.0
	if actor.data.money >= int(days * 5):
		actor.data.money -= int(days * 5)
		base_heal += days * 20.0

	actor.add_stat("need_healing", -base_heal)
	actor.data.stamina += int(base_heal)
	if actor.data.stamina > 100: actor.data.stamina = 100

	if actor.data.need_healing <= 0:
		actor.data.need_healing = 0
		if randf() < 0.2:
			log_event(actor, "历经 %.1f 天的打坐运功，体内伤势已完全痊愈。" % days)
	else:
		if randf() < 0.05:
			log_event(actor, "默默运功疗伤了 %.1f 天，伤势有所好转。" % days)
