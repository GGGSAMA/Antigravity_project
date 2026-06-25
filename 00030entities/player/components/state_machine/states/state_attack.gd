extends "res://00030entities/player/components/state_machine/states/player_state.gd"

var combo_window_open: bool = false
var is_left: bool = true

func enter(msg: Dictionary = {}) -> void:
	combo_window_open = false
	var action = msg.get("action", "Attack_Left")
	is_left = (action == "Attack_Left")

	# 让 CombatComponent 执行真正的施法或挥砍逻辑
	var combat_comp = player.get_node_or_null("CombatComponent")
	if combat_comp and combat_comp.has_method("execute_attack_from_state"):
		combat_comp.execute_attack_from_state(is_left)
	else:
		# Fallback: 如果没有 combat_comp，直接播放动画
		if anim_node and anim_node.has_method("set_animation_state"):
			anim_node.set_animation_state("attack")

func physics_process(_delta: float) -> void:
	# 检查动画是否结束，或者是否进入了连招窗口
	# 简单模拟：如果动画结束，返回 idle
	var is_playing = false
	if anim_node and anim_node.get("anim_player"):
		is_playing = anim_node.anim_player.is_playing()

		# 假设动画的后 30% 是可以打断的连击窗口
		if is_playing:
			var pos = anim_node.anim_player.current_animation_position
			var length = anim_node.anim_player.current_animation_length
			if length > 0 and (pos / length) > 0.7:
				combo_window_open = true

	if combo_window_open:
		var input_buffer = player.get_node_or_null("InputBufferComp")
		if input_buffer:
			var action = input_buffer.consume_action(["Attack_Left", "Attack_Right"] as Array[String])
			if action != "":
				# 触发下一段连击
				state_machine.transition_to("attack", {"action": action})
				return

	if not is_playing:
		var speed = Vector2(player.velocity.x, player.velocity.z).length()
		if speed > 0.5:
			state_machine.transition_to("move")
		else:
			state_machine.transition_to("idle")
