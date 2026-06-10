extends Node
class_name CameraComponent

@export var character: CharacterBody3D
@export var head: Node3D
@export var camera: Camera3D

@export var mouse_sensitivity: float = 0.0008

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not character: character = get_parent() as CharacterBody3D
	if character and not head: head = character.get_node_or_null("Head")
	if head and not camera: camera = head.get_node_or_null("Camera3D")

@export_group("Flight Camera Tilt")
@export var flight_tilt_sensitivity: float = 0.01
@export var flight_tilt_max: float = 0.5
@export var flight_tilt_smoothness: float = 1.5

var mouse_turn_velocity: float = 0.0
var fov_boost: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not character or not head: return
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
		
	var hud = character.get_node_or_null("HUD")
	var any_vis = (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)
		
	if not any_vis and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var is_flying = character.get("is_flying")
			# 飞行时降低鼠标灵敏度，增加“仙人御风”的重量感和飘逸感
			var actual_sens = mouse_sensitivity * (0.5 if is_flying else 1.0)
			character.rotate_y(-event.relative.x * actual_sens)
			head.rotate_x(-event.relative.y * actual_sens)
			head.rotation.x = clamp(head.rotation.x, -PI/2.5, PI/2.5)
			# 累积鼠标移动速度（迟钝感需要平滑累积）
			mouse_turn_velocity = lerp(mouse_turn_velocity, event.relative.x * 20.0, 0.1)

func _physics_process(delta: float) -> void:
	if not camera: return
	var is_flying = character.get("is_flying")
	var current_gear = character.get("current_speed_gear") if character.get("current_speed_gear") != null else 0
	
	# 鼠标转向速度随时间缓慢衰减
	mouse_turn_velocity = lerp(mouse_turn_velocity, 0.0, delta * 3.0)
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_tilt = 0.0
	
	if is_flying:
		target_tilt = -input_dir.x * 0.15
		target_tilt -= mouse_turn_velocity * flight_tilt_sensitivity
		target_tilt = clamp(target_tilt, -flight_tilt_max, flight_tilt_max)
	
	if is_flying and Input.is_action_pressed("sprint"):
		fov_boost = lerp(fov_boost, 1.0, delta * 4.0)
	else:
		fov_boost = lerp(fov_boost, 0.0, delta * 3.0)
		
	var target_fov = 75.0
	if is_flying:
		target_fov = lerp(75.0, 110.0, clamp(float(current_gear)/3.0, 0.0, 1.0) * 0.5 + fov_boost * 0.5)
		
	camera.fov = lerp(camera.fov, target_fov, delta * 5.0)
	
	# 飞行时应用非常缓慢的插值，营造笨重、迟钝的滑翔机感
	var current_smoothness = flight_tilt_smoothness if is_flying else 5.0
	camera.rotation.z = lerp(camera.rotation.z, target_tilt, delta * current_smoothness)
