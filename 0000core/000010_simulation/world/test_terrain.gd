extends SceneTree

func _init():
	var file = FileAccess.open("res://methods.txt", FileAccess.WRITE)
	if not file:
		return
	var packed = load("res://main.tscn")
	var scene = packed.instantiate()
	var terrain = _find_terrain(scene)
	if terrain and terrain.data:
		var methods = terrain.data.get_method_list()
		for m in methods:
			file.store_line(m["name"])
	file.close()
	quit()

func _find_terrain(node: Node) -> Node:
	if node.name == "Terrain3D" or node is Terrain3D:
		return node
	for child in node.get_children():
		var res = _find_terrain(child)
		if res:
			return res
	return null
