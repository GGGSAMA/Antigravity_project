extends ChronosAction

func _init() -> void:
	action_id = "gather"
	action_name = "采集资源"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return true 

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var wander = load("res://0000core/000010_simulation/actions/action_wander.gd").new()
	wander.settle_time_chunk(actor, hours_passed)
