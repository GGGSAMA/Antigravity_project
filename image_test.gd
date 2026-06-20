extends SceneTree

func _init():
	var file = FileAccess.open("res://image_test.txt", FileAccess.WRITE)
	if not file:
		return
	if Image.has_method("create"):
		file.store_line("Has create")
	if Image.has_method("create_empty"):
		file.store_line("Has create_empty")
	
	# Try calling create_empty
	var img = Image.create_empty(10, 10, false, Image.FORMAT_RF)
	if img:
		file.store_line("create_empty worked")
	file.close()
	quit()
