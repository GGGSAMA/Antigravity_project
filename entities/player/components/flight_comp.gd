extends Node
class_name FlightComponent

@export var character: CharacterBody3D
@export var camera: Camera3D
@export var head: Node3D
@export var spring_arm: Node3D
@export var tps_camera_pos: Marker3D
@export var player_model: Node3D

@export_group("Flight Settings")
@export var debug_speed_multiplier: float = 10.0

func _ready() -> void:
	if not character: character = get_parent() as CharacterBody3D
	if character and not head: head = character.get_node_or_null("Head")
	if head and not camera: camera = head.get_node_or_null("Camera3D")
	if head and not spring_arm: spring_arm = head.get_node_or_null("SpringArm3D")
	if spring_arm and not tps_camera_pos: tps_camera_pos = spring_arm.get_node_or_null("TPSCameraPos")
	if character and not player_model: player_model = character.get_node_or_null("PlayerModel")

const FLIGHT_ACTIVATE_HOLD_TIME: float = 0.35

var fly_hold_time: float = 0.0
var alt_press_time: float = 0.0
var brake_start_velocity: Vector3 = Vector3.ZERO
var current_speed_gear_float: float = 0.0

var dash_camera_boost: float = 0.0

var last_alt_time: float = -1.0
var alt_was_pressed: bool = false
var is_rapid_descent: bool = false

func _physics_process(delta: float) -> void:
	if not character: return
	
	var any_vis = (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)

	var is_flying = character.get("is_flying")
	
	if Input.is_action_pressed("sprint") and not any_vis:
		dash_camera_boost = lerp(dash_camera_boost, 1.0, delta * 3.0)
	else:
		dash_camera_boost = lerp(dash_camera_boost, 0.0, delta * 2.0)
	
	# Activation logic
	if character.is_on_floor():
		if is_flying:
			_set_flying(false)
		fly_hold_time = 0.0
	else:
		if Input.is_action_pressed("jump") and not any_vis:
			fly_hold_time += delta
			if fly_hold_time >= FLIGHT_ACTIVATE_HOLD_TIME and not is_flying:
				_set_flying(true)
		else:
			if not is_flying:
				fly_hold_time = 0.0

	# Flight Movement
	if is_flying:
		_handle_flight_movement(delta, any_vis)
		
	# Camera Transition (俯瞰视角随档位拉远)
	var target_cam_local_pos = Vector3.ZERO
	if is_flying and spring_arm and tps_camera_pos:
		target_cam_local_pos = head.to_local(tps_camera_pos.global_position)
		# 根据档位和按住 Shift 的爆发力动态计算拉远和拔高
		var pullback = current_speed_gear_float * 1.0 + dash_camera_boost * 2.0
		var height_up = current_speed_gear_float * 0.2 + dash_camera_boost * 0.5
		target_cam_local_pos += Vector3(0, height_up, pullback)
		
	if camera:
		camera.position = camera.position.lerp(target_cam_local_pos, delta * 4.0)

func _set_flying(state: bool) -> void:
	character.set("is_flying", state)
	
	var hud = character.get_node_or_null("HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("【御空飞行】仙风呼啸，踏空而行" if state else "【御气降临】从天而降，平稳着陆")
		
	# 高手腾飞的爆发力
	if state:
		# 向上拔起的高度 (旱地拔葱)
		character.velocity.y = 18.0
		# 略微带一点向前的冲势 (视角正前方)
		var forward = Vector3.ZERO
		if head: forward = -head.global_transform.basis.z
		else: forward = -character.transform.basis.z
		character.velocity += forward * 10.0
		
	# Visual isolation
	if character.get("viewmodel"): character.get("viewmodel").visible = not state
	if hud and hud.get("crosshair"): hud.get("crosshair").visible = not state
	if player_model: player_model.visible = state

func _handle_flight_movement(delta: float, any_vis: bool) -> void:
	var stats = character.get("stats")
	var player_speed_stat = stats.get("speed") if stats and stats.get("speed") != null else 100
	
	var base_fly_speed = 10.0 + float(player_speed_stat) * 0.1 
	var max_gears = max(1.0, float(player_speed_stat) / 33.0) 
	
	var alt_pressed = Input.is_key_pressed(KEY_ALT) and not any_vis
	if alt_pressed:
		alt_press_time += delta
		if alt_press_time >= 0.3:
			is_rapid_descent = true
		else:
			# 按下前 0.3 秒视为急刹车
			current_speed_gear_float = 0.0
			character.velocity.x = lerp(character.velocity.x, 0.0, delta * 10.0)
			character.velocity.z = lerp(character.velocity.z, 0.0, delta * 10.0)
			character.velocity.y = lerp(character.velocity.y, 0.0, delta * 10.0)
	else:
		alt_press_time = 0.0
		is_rapid_descent = false
	
	if is_rapid_descent:
		character.velocity.x = lerp(character.velocity.x, 0.0, delta * 15.0)
		character.velocity.z = lerp(character.velocity.z, 0.0, delta * 15.0)
		
		# 极速坠落！放开限速，赋予极端的初速度
		character.velocity.y = -max(500.0, character.global_position.y * 5.0)
		
		# 【CCD 射线预判防穿透】在物理移动前，发射一根预测射线
		var space_state = character.get_world_3d().direct_space_state
		var fall_dist = abs(character.velocity.y * delta) + 2.0
		var query = PhysicsRayQueryParameters3D.create(character.global_position, character.global_position + Vector3.DOWN * fall_dist)
		var result = space_state.intersect_ray(query)
		
		if result:
			# 如果这一帧即将砸穿地面，或者距离地面不足 2 米，直接“吸附”并引爆特效
			character.global_position.y = result.position.y
			character.velocity.y = 0.0
			is_rapid_descent = false
			_set_flying(false)
			_spawn_landing_impact_vfx()
		else:
			character.move_and_slide()
			# 保底检测
			if character.is_on_floor():
				is_rapid_descent = false
				_set_flying(false)
				_spawn_landing_impact_vfx()
		return
		
	# Flight Control Mapping
	var is_accelerating = Input.is_action_pressed("jump") and not any_vis
	var is_boosting = Input.is_action_pressed("sprint") and not any_vis
	var is_braking = Input.is_action_pressed("move_down") and not any_vis
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if is_braking: input_dir.y = 0.0 # Prevent moving backwards visually when decelerating
	
	# Gear (Throttle) Logic
	if is_accelerating:
		current_speed_gear_float = move_toward(current_speed_gear_float, max_gears, delta * 1.5)
	elif is_braking:
		current_speed_gear_float = move_toward(current_speed_gear_float, 0.0, delta * 3.0)
		
	character.set("current_speed_gear", int(current_speed_gear_float))
	
	# Final Target Speed
	var active_speed = (base_fly_speed + current_speed_gear_float * 15.0) * debug_speed_multiplier
	if is_boosting:
		active_speed *= 2.5 # NO2 强力加速
		if Input.is_action_just_pressed("sprint"):
			# 氮气爆发初速度
			var burst_dir = -head.global_transform.basis.z.normalized() if head else -character.transform.basis.z.normalized()
			character.velocity += burst_dir * (30.0 * debug_speed_multiplier)

	# Normal Flight
	if not alt_pressed:
		# Superman Flight vector (Forward based on where camera looks + manual strafing)
		var forward_dir = Vector3.ZERO
		if head: forward_dir = -head.global_transform.basis.z.normalized()
		
		var manual_dir = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# 当档位提高时，自动巡航的权重更大；低档位时，依然可以使用 WASD 平移
		var gear_ratio = clamp(current_speed_gear_float / max_gears, 0.0, 1.0)
		var target_vel = forward_dir * (active_speed * gear_ratio) + manual_dir * (active_speed * (1.0 - gear_ratio * 0.5))
		
		# 平滑插值应用速度
		character.velocity.x = lerp(character.velocity.x, target_vel.x, delta * 3.0)
		character.velocity.z = lerp(character.velocity.z, target_vel.z, delta * 3.0)
		character.velocity.y = lerp(character.velocity.y, target_vel.y, delta * 3.0)
		
		# 提供一个轻微的反重力悬浮保底
		if target_vel.length_squared() < 1.0 and not is_accelerating:
			character.velocity.y = lerp(character.velocity.y, 0.0, delta * 2.0)

	character.move_and_slide()

func _spawn_landing_impact_vfx():
	var hud = character.get_node_or_null("HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("【轰！】天神降临，大地震颤")
		
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.6, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 2.0
	torus.material = mat
	mesh_inst.mesh = torus
	
	character.get_parent().add_child(mesh_inst)
	mesh_inst.global_position = character.global_position + Vector3(0, 0.2, 0)
	
	var tween = create_tween()
	tween.tween_property(mesh_inst, "scale", Vector3(15.0, 0.1, 15.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tween.tween_callback(mesh_inst.queue_free)
