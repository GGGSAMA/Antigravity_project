extends Node
class_name MovementComponent

@export var character: CharacterBody3D
@export var base_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 4.5

# Source Engine / CSGO 风格移动参数
@export var ground_acceleration: float = 14.0
@export var ground_friction: float = 8.0
@export var air_acceleration: float = 2.5
@export var air_speed_cap: float = 1.5 # 限制空中拐弯增加的速度上限，但保留原有惯性速度

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	if not character: character = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not character: character = get_parent() as CharacterBody3D
	if not character or character.get("is_flying"): return
	
	var any_vis = (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)

	# 跳跃
	if Input.is_action_just_pressed("jump") and character.is_on_floor() and not any_vis:
		character.velocity.y = jump_velocity

	# 获取输入向量
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var stats = character.get("stats")
	var speed_mult = stats.get_speed_multiplier() if stats and stats.has_method("get_speed_multiplier") else 1.0
	
	# 下蹲减速
	var is_crouching = Input.is_key_pressed(KEY_CTRL)
	var crouch_mult = 0.5 if is_crouching else 1.0
	
	var active_speed = (sprint_speed if Input.is_action_pressed("sprint") else base_speed) * speed_mult * crouch_mult

	# 头部下蹲动画
	var head = character.get_node_or_null("Head")
	if head:
		head.position.y = lerp(head.position.y, 0.8 if is_crouching else 1.6, delta * 10.0)

	var current_velocity = character.velocity
	current_velocity.y = 0.0 # 在 2D 平面上计算摩擦力和加速
	
	if character.is_on_floor():
		# 地面摩擦力
		var speed = current_velocity.length()
		if speed > 0.1:
			var drop = speed * ground_friction * delta
			var friction_mult = max(speed - drop, 0.0) / speed
			current_velocity *= friction_mult
		else:
			current_velocity = Vector3.ZERO
			
		# 地面加速度
		var current_speed_in_dir = current_velocity.dot(direction)
		var add_speed = active_speed - current_speed_in_dir
		if add_speed > 0:
			var accel_speed = ground_acceleration * active_speed * delta
			accel_speed = min(accel_speed, add_speed)
			current_velocity += direction * accel_speed
	else:
		# 空中加速度 (CSGO 空中连跳/空连转向手感)
		var current_speed_in_dir = current_velocity.dot(direction)
		var add_speed = air_speed_cap - current_speed_in_dir
		if add_speed > 0:
			var accel_speed = air_acceleration * air_speed_cap * delta
			accel_speed = min(accel_speed, add_speed)
			current_velocity += direction * accel_speed

	# 还原垂直速度
	character.velocity.x = current_velocity.x
	character.velocity.z = current_velocity.z
	
	if not character.is_on_floor():
		character.velocity.y -= gravity * delta

	character.move_and_slide()
