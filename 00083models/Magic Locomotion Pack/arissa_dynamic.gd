extends Node3D

var anim_player: AnimationPlayer = null
@export var anim_map: Dictionary = {}

func _ready():
	var glb_scene = load("res://00083models/Lite Magic Pack/Arissa.fbx")
	if not glb_scene:
		push_error("Arissa.fbx not found!")
		return
		
	var model = glb_scene.instantiate()
	add_child(model)
	
	var bodies = model.find_children("*", "PhysicsBody3D", true, false)
	for b in bodies:
		b.process_mode = Node.PROCESS_MODE_DISABLED
		b.set_process(false)
		b.set_physics_process(false)
		if b is CollisionObject3D:
			b.collision_layer = 0
			b.collision_mask = 0
			
	model.scale = Vector3(1.0, 1.0, 1.0)
		
	# 获取 AnimationPlayer
	anim_player = model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		for child in model.get_children():
			if child is AnimationPlayer:
				anim_player = child
				break
	if not anim_player:
		anim_player = AnimationPlayer.new()
		model.add_child(anim_player)
	
	var lib_path = "res://00083models/Lite Magic Pack/magic_library.res"
	var magic_lib = null
	
	if ResourceLoader.exists(lib_path):
		magic_lib = load(lib_path)
		print("Loaded cached magic_library.res!")
	else:
		print("magic_library.res not found! Auto-baking animations now...")
		magic_lib = AnimationLibrary.new()
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
						_extract_animation("res://00083models/Lite Magic Pack/" + clean_name, magic_lib)
				file_name = dir.get_next()
		var err = ResourceSaver.save(magic_lib, lib_path)
		if err == OK:
			print("Auto-baked and saved magic_library.res successfully!")
		else:
			push_error("Failed to save magic_library.res! Error: " + str(err))
			
	anim_player.add_animation_library("magic", magic_lib)
	
	var anims = magic_lib.get_animation_list()
	for a in anims:
		var lower_a = a.to_lower()
		if "idle" in lower_a and not anim_map.has("idle"): anim_map["idle"] = a
		elif "walk" in lower_a and not anim_map.has("walk"): anim_map["walk"] = a
		elif "run" in lower_a and not anim_map.has("run"): anim_map["run"] = a
		elif ("attack" in lower_a or "slash" in lower_a) and not anim_map.has("attack"): anim_map["attack"] = a
		elif "jump" in lower_a and not anim_map.has("jump"): anim_map["jump"] = a
		
	if not anim_map.has("walk") and anim_map.has("run"): anim_map["walk"] = anim_map["run"]
	if not anim_map.has("run") and anim_map.has("walk"): anim_map["run"] = anim_map["walk"]
	
	if anim_map.has("idle"):
		anim_player.play("magic/" + anim_map["idle"])

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
		for i in range(track_count):
			var track_path = anim.track_get_path(i)
			var path_str = str(track_path)
			
			if "Hips" in path_str or "Root" in path_str:
				if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
					var key_count = anim.track_get_key_count(i)
					for k in range(key_count):
						var val = anim.track_get_key_value(i, k)
						if typeof(val) == TYPE_VECTOR3:
							val.x = 0
							val.z = 0
							anim.track_set_key_value(i, k, val)
		
		var lower_name = path.get_file().get_basename().to_lower()
		if "idle" in lower_name or "walk" in lower_name or "run" in lower_name:
			anim.loop_mode = Animation.LOOP_LINEAR
			
		var save_name = path.get_file().get_basename()
		new_lib.add_animation(save_name, anim)
		
	instance.queue_free()

func set_animation_state(state: String):
	if not anim_player: return
	var target_anim = ""
	if anim_map.has(state): target_anim = "magic/" + anim_map[state]
	elif state == "attack" and anim_map.has("attack"): target_anim = "magic/" + anim_map["attack"]
	elif anim_map.has("idle"): target_anim = "magic/" + anim_map["idle"]
		
	if target_anim != "" and anim_player.current_animation != target_anim:
		anim_player.play(target_anim, 0.2)
