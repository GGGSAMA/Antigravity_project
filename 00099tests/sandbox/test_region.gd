extends SceneTree

func _init():
	var file = FileAccess.open("res://generator_log2.txt", FileAccess.WRITE)
	var terrain = Terrain3D.new()
	if terrain:
		file.store_line("Terrain3D created.")
		if ClassDB.class_exists("Terrain3DRegion"):
			file.store_line("Terrain3DRegion exists.")
		else:
			file.store_line("Terrain3DRegion does NOT exist.")
	file.close()
	quit()
