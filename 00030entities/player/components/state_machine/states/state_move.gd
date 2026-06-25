extends "res://00030entities/player/components/state_machine/states/player_state.gd"

func enter(_msg: Dictionary = {}) -> void:
	pass

func physics_process(_delta: float) -> void:
	var speed = Vector2(player.velocity.x, player.velocity.z).length()
	if speed <= 0.5:
		state_machine.transition_to("idle")
		return

	if anim_node and anim_node.has_method("set_animation_state"):
		if speed > 3.5:
			anim_node.set_animation_state("run")
		else:
			anim_node.set_animation_state("walk")

	# 检查缓冲区的攻击和闪避输入 (移动中可以发起闪避和攻击)
	var input_buffer = player.get_node_or_null("InputBufferComp")
	if input_buffer:
		var dodge_action = input_buffer.consume_action(["Dodge"] as Array[String])
		if dodge_action != "":
			state_machine.transition_to("dodge")
			return

		var action = input_buffer.consume_action(["Attack_Left", "Attack_Right"] as Array[String])
		if action != "":
			state_machine.transition_to("attack", {"action": action})
