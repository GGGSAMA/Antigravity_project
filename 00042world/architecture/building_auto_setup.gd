extends Node3D
class_name BuildingAutoSetup

func _ready() -> void:
	# 延迟一帧执行，确保子节点(FBX自动生成的Mesh)已经完全加载
	call_deferred("_setup_building")

func _setup_building() -> void:
	# 创建材质
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.4, 0.25, 0.15) # 木头色
	mat_wood.roughness = 0.8

	var mat_roof = StandardMaterial3D.new()
	mat_roof.albedo_color = Color(0.2, 0.25, 0.3) # 青瓦色
	mat_roof.roughness = 0.9

	_process_node(self, mat_wood, mat_roof)
	print("[BuildingAutoSetup] 模型材质和碰撞体已自动生成！")

func _process_node(node: Node, mat_wood: Material, mat_roof: Material) -> void:
	if node is MeshInstance3D:
		var node_name = node.name.to_lower()
		if "roof" in node_name or "top" in node_name:
			node.set_surface_override_material(0, mat_roof)
		else:
			node.set_surface_override_material(0, mat_wood)

		# 如果还没有碰撞体，就自动生成
		var has_collision = false
		for child in node.get_children():
			if child is StaticBody3D:
				has_collision = true
				break

		if not has_collision:
			node.create_trimesh_collision()

	for child in node.get_children():
		_process_node(child, mat_wood, mat_roof)
