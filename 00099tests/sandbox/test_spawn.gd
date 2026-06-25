extends SceneTree

func _init():
	print("Loading main.tscn...")
	var scene = load("res://main.tscn")
	var root = scene.instantiate()

	print("Looking for Terrain3D...")
	var terrain = _find_terrain(root)
	if terrain:
		print("Found Terrain3D: ", terrain.name)
		print("Terrain bounds...")
		if terrain.has_method("get_region_locations"):
			print("Regions: ", terrain.get_region_locations())

		# check height at (0, 0)
		var h = 0.0
		if terrain.storage and terrain.storage.has_method("get_height"):
			h = terrain.storage.get_height(Vector3(0, 0, 0))
		print("Height at (0, 0): ", h)

		if terrain.storage and terrain.storage.has_method("get_height"):
			print("Height at (4000, 4000): ", terrain.storage.get_height(Vector3(4000, 0, 4000)))

	else:
		print("No Terrain3D found.")

	print("Checking PlayerSpawn...")
	var spawn = root.get_node_or_null("PlayerSpawn")
	if spawn:
		print("PlayerSpawn global_pos: ", spawn.global_position)
	else:
		print("PlayerSpawn not found.")

	quit()

func _find_terrain(node: Node) -> Node:
	if node.get_class() == "Terrain3D":
		return node
	for c in node.get_children():
		var res = _find_terrain(c)
		if res: return res
	return null
