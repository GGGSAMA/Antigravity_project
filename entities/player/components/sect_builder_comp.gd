extends Node

@export var pillar_scene_path: String = "res://world/architecture/pillar.tscn"

var is_equipped: bool = false
var preview_instance: Node3D = null

var build_timer: float = 0.0
const BUILD_TIME_REQUIRED: float = 3.0

var ui_canvas: CanvasLayer = null
var progress_bar: ProgressBar = null
var prompt_label: Label = null

func _ready():
	_setup_ui()

func _setup_ui():
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_canvas.add_child(control)
	
	prompt_label = Label.new()
	prompt_label.text = "Sect Builder: [1] to Equip"
	prompt_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position.y = 20
	control.add_child(prompt_label)
	
	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	progress_bar.custom_minimum_size = Vector2(200, 20)
	progress_bar.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, get_viewport().get_visible_rect().size.y / 2 + 50)
	progress_bar.max_value = BUILD_TIME_REQUIRED
	progress_bar.value = 0.0
	progress_bar.visible = false
	control.add_child(progress_bar)

func _process(delta):
	# Toggle equip
	if Input.is_action_just_pressed("ui_1") or Input.is_physical_key_pressed(KEY_1):
		# Prevent multiple triggers in same frame if both map to same
		if Input.is_physical_key_pressed(KEY_1) and Input.is_action_just_pressed("ui_1"):
			pass # handle below
		if Input.is_key_pressed(KEY_1):
			pass
			
	# Let's just use Input.is_key_pressed, but properly debounced or just use Input.is_physical_key_pressed with a small delay or use InputEventKey
	pass

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_1 and not event.echo:
		is_equipped = !is_equipped
		prompt_label.text = "Sect Builder: [1] to Unequip" if is_equipped else "Sect Builder: [1] to Equip"
		if not is_equipped:
			_clear_preview()
			build_timer = 0.0
			progress_bar.visible = false

func _physics_process(delta):
	if not is_equipped:
		return
		
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().get_visible_rect().size / 2
	var origin = camera.project_ray_origin(screen_center)
	var end = origin + camera.project_ray_normal(screen_center) * 100.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	# query.collision_mask = ... (if needed)
	
	var result = space_state.intersect_ray(query)
	var hit_pos = Vector3.ZERO
	var has_hit = false
	
	if result:
		hit_pos = result.position
		has_hit = true
		if not preview_instance:
			_create_preview()
		if preview_instance:
			preview_instance.global_position = hit_pos
			preview_instance.visible = true
	else:
		if preview_instance:
			preview_instance.visible = false
			
	_handle_building(delta, has_hit, hit_pos)

func _create_preview():
	if ResourceLoader.exists(pillar_scene_path):
		var scene = load(pillar_scene_path) as PackedScene
		if scene:
			preview_instance = scene.instantiate()
			get_tree().current_scene.add_child(preview_instance)
			
			# Make it semi-transparent
			_make_transparent(preview_instance)

func _make_transparent(node: Node):
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if mat:
			var new_mat = mat.duplicate()
			if new_mat is StandardMaterial3D:
				new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				new_mat.albedo_color.a = 0.5
				node.set_surface_override_material(0, new_mat)
	for child in node.get_children():
		_make_transparent(child)

func _clear_preview():
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null

func _handle_building(delta: float, has_hit: bool, hit_pos: Vector3):
	var is_holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	if has_hit and is_holding:
		build_timer += delta
		progress_bar.visible = true
		progress_bar.value = build_timer
		progress_bar.position = get_viewport().get_visible_rect().size / 2 + Vector2(-100, 50)
		
		if build_timer >= BUILD_TIME_REQUIRED:
			_spawn_pillar(hit_pos)
			build_timer = 0.0
			is_equipped = false
			prompt_label.text = "Sect Builder: [1] to Equip"
			_clear_preview()
			progress_bar.visible = false
	else:
		build_timer = 0.0
		progress_bar.visible = false

func _spawn_pillar(pos: Vector3):
	if ResourceLoader.exists(pillar_scene_path):
		var scene = load(pillar_scene_path) as PackedScene
		if scene:
			var inst = scene.instantiate()
			get_tree().current_scene.add_child(inst)
			inst.global_position = pos
			
			# Claim territory
			if WorldGridManager.has_method("claim_territory_radius"):
				WorldGridManager.claim_territory_radius(pos, 1, "Player_Sect")
				print("Claimed territory for Player_Sect at: ", pos)
