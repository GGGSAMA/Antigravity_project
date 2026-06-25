@tool
extends EditorScript

func _run() -> void:
	var fbx_path = "res://00083models/building/3d-model.fbx"
	var save_path = "res://00083models/building/building_processed.tscn"

	var packed_scene = load(fbx_path) as PackedScene
	if not packed_scene:
		print("Failed to load FBX: ", fbx_path)
		return

	var root = packed_scene.instantiate()

	# 创建两个简单的材质来给它上色，避免纯白
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.4, 0.25, 0.15) # 木头色
	mat_wood.roughness = 0.8

	var mat_roof = StandardMaterial3D.new()
	mat_roof.albedo_color = Color(0.2, 0.25, 0.3) # 青瓦色
	mat_roof.roughness = 0.9

	# 遍历子节点并处理网格和碰撞
	_process_node(root, mat_wood, mat_roof)

	var new_packed = PackedScene.new()
	new_packed.pack(root)
	var err = ResourceSaver.save(new_packed, save_path)

	if err == OK:
		print("Successfully processed and saved building to: ", save_path)
	else:
		print("Failed to save: ", err)

func _process_node(node: Node, mat_wood: Material, mat_roof: Material) -> void:
	if node is MeshInstance3D:
		# 简单根据名字或者大小判断给个材质，这里先统一给木头色，如果是房顶可能名字带roof
		var node_name = node.name.to_lower()
		if "roof" in node_name or "top" in node_name:
			node.set_surface_override_material(0, mat_roof)
		else:
			node.set_surface_override_material(0, mat_wood)

		# 生成静态碰撞体 (Trimesh)
		node.create_trimesh_collision()

		# 找到生成的 StaticBody3D，并修改 Owner 为 root，以防保存时丢失
		for child in node.get_children():
			if child is StaticBody3D:
				child.owner = node.owner if node.owner else node
				for shape in child.get_children():
					if shape is CollisionShape3D:
						shape.owner = node.owner if node.owner else node

	for child in node.get_children():
		_process_node(child, mat_wood, mat_roof)
