@tool
extends SceneTree

func _init() -> void:
	print("[Remove Stats] Starting...")
	var scenes = [
		"res://00030entities/player/player.tscn",
		"res://00030entities/npc/npc.tscn",
		"res://00030entities/npc/npc_base.tscn"
	]
	
	for path in scenes:
		var packed = load(path) as PackedScene
		if not packed:
			print("Could not load: ", path)
			continue
		
		var root = packed.instantiate()
		var stats_node = root.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		
		if stats_node:
			print("Removing Stats from ", path)
			root.remove_child(stats_node)
			stats_node.free()
			
			var new_packed = PackedScene.new()
			new_packed.pack(root)
			var err = ResourceSaver.save(new_packed, path)
			if err == OK:
				print("Successfully saved ", path)
			else:
				print("Failed to save ", path, " error: ", err)
		else:
			print("Stats node not found in ", path)

	quit(0)
