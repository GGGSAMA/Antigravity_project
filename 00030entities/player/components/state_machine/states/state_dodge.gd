extends PlayerState

@export var dodge_speed: float = 25.0
@export var dodge_duration: float = 0.4
@export var dodge_friction: float = 5.0

var dodge_timer: float = 0.0
var dodge_dir: Vector3 = Vector3.ZERO

func enter(msg: Dictionary = {}) -> void:
	dodge_timer = dodge_duration
	player.set("is_invincible", true) # 无敌帧开始

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera_comp = player.get_node_or_null("CameraComponent")
	
	if input_dir != Vector2.ZERO and camera_comp and camera_comp.head:
		var forward = -camera_comp.head.global_transform.basis.z
		var right = camera_comp.head.global_transform.basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		dodge_dir = (right * input_dir.x + forward * input_dir.y).normalized()
	else:
		# 没有输入时，向正后方翻滚
		dodge_dir = player.global_transform.basis.z.normalized()

	player.velocity = dodge_dir * dodge_speed

	# 尝试播放翻滚/闪避动画
	if anim_node and anim_node.has_method("play_anim"):
		anim_node.play_anim("dodge") # 占位动画名

	if has_node("/root/Log"):
		get_node("/root/Log").debug("Combat", "执行闪避/翻滚")

func physics_process(delta: float) -> void:
	dodge_timer -= delta
	
	# 摩擦力衰减
	var current_h_vel = Vector3(player.velocity.x, 0, player.velocity.z)
	current_h_vel = current_h_vel.lerp(Vector3.ZERO, dodge_friction * delta)
	player.velocity.x = current_h_vel.x
	player.velocity.z = current_h_vel.z

	# 重力
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta

	player.move_and_slide()

	if dodge_timer <= 0.0:
		state_machine.transition_to("idle")

func exit() -> void:
	player.set("is_invincible", false) # 结束无敌帧
