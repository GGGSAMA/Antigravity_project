@tool
extends EditorScript

func _run() -> void:
	print("开始烘焙动画库...")
	var glb_scene = load("res://00083models/Lite Magic Pack/Arissa.fbx")
	if not glb_scene:
		print("未找到 Arissa.fbx!")
		return

	var anim_player = null
	var instance = glb_scene.instantiate()
	for child in instance.get_children():
		if child is AnimationPlayer:
			anim_player = child
			break

	if not anim_player:
		print("Arissa.fbx 中未找到 AnimationPlayer!")
		instance.queue_free()
		return

	var new_lib = AnimationLibrary.new()
	var dir = DirAccess.open("res://00083models/Lite Magic Pack/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".fbx") and file_name != "Arissa.fbx":
				var clean_name = file_name
				if file_name.ends_with(".import"):
					clean_name = file_name.replace(".import", "")
				if clean_name.ends_with(".fbx"):
					_extract_animation("res://00083models/Lite Magic Pack/" + clean_name, new_lib)
			file_name = dir.get_next()

	# 保存资源
	var save_path = "res://00083models/Lite Magic Pack/magic_library.res"
	var err = ResourceSaver.save(new_lib, save_path)
	if err == OK:
		print("动画库烘焙成功: ", save_path)
	else:
		print("动画库烘焙失败, 错误码: ", err)

	instance.queue_free()

func _extract_animation(path: String, new_lib: AnimationLibrary):
	var anim_scene = load(path)
	if not anim_scene: return
	var instance = anim_scene.instantiate()
	var ap = null
	for c in instance.get_children():
		if c is AnimationPlayer:
			ap = c
			break
	if not ap:
		instance.queue_free()
		return

	for anim_name in ap.get_animation_list():
		var anim = ap.get_animation(anim_name).duplicate()
		var track_count = anim.get_track_count()
		for i in range(track_count - 1, -1, -1):
			var track_path = anim.track_get_path(i)
			var path_str = str(track_path)

			if "Hips" in path_str:
				# 剥离位移
				var key_count = anim.track_get_key_count(i)
				for k in range(key_count):
					var val = anim.track_get_key_value(i, k)
					if typeof(val) == TYPE_VECTOR3:
						val.x = 0
						val.z = 0
						anim.track_set_key_value(i, k, val)

			if "mixamorig" in path_str:
				var new_path = path_str.replace("mixamorig", "")
				anim.track_set_path(i, NodePath(new_path))

		var lower_name = path.get_file().get_basename().to_lower()
		if "idle" in lower_name or "walk" in lower_name or "run" in lower_name:
			anim.loop_mode = Animation.LOOP_LINEAR

		var save_name = path.get_file().get_basename()
		new_lib.add_animation(save_name, anim)
		print(" -> 提取动画: ", save_name)

	instance.queue_free()
