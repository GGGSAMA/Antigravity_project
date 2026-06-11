extends SceneTree

func _init():
	var classes = ["Terrain3D", "Terrain3DData", "Terrain3DStorage", "Terrain3DInstancer", "Terrain3DAssets"]
	for c in classes:
		print("Has class ", c, ": ", ClassDB.class_exists(c))
		if ClassDB.class_exists(c):
			var methods = ClassDB.class_get_method_list(c)
			print("--- Methods for ", c, " ---")
			for m in methods:
				if "import" in m.name or "height" in m.name or "add_" in m.name:
					print(m.name)
	quit()
