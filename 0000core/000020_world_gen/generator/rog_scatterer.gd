extends Node3D
class_name RogScatterer

@export var prop_scenes: Array[PackedScene] = []
@export var spawn_radius: float = 300.0
@export var spawn_count: int = 50

func _ready() -> void:
	if prop_scenes.is_empty():
		return

	# 等待一帧，确保物理服务器和地形已经准备就绪
	await get_tree().process_frame
	await get_tree().physics_frame

	_scatter_props()

func _scatter_props() -> void:
	if prop_scenes.is_empty():
		push_error("RogScatterer: No prop scenes assigned.")
		return

	var space_state = get_world_3d().direct_space_state
	var rng = RandomNumberGenerator.new()
	var current_seed = "默认神界"
	if has_node("/root/WorldState"):
		current_seed = get_node("/root/WorldState").current_seed
	rng.seed = current_seed.hash()

	for i in range(spawn_count):
		# 随机位置
		var angle = rng.randf() * PI * 2.0
		var radius = rng.randf_range(20.0, spawn_radius) # 不要贴脸生成

		var spawn_x = cos(angle) * radius
		var spawn_z = sin(angle) * radius

		var ray_origin = Vector3(spawn_x, 1000.0, spawn_z)
		var ray_end = Vector3(spawn_x, -100.0, spawn_z)

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = space_state.intersect_ray(query)

		if result:
			# 射线命中地形表面
			var prop_scene = prop_scenes[rng.randi() % prop_scenes.size()]
			if prop_scene:
				var prop_instance = prop_scene.instantiate() as Node3D
				add_child(prop_instance)
				prop_instance.global_position = result.position
				# 随机旋转
				prop_instance.rotation.y = rng.randf() * PI * 2.0
		else:
			# 射线没有命中，可能那个位置在地图之外或者高度太低
			pass
