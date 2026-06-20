@tool
extends EditorScript

func _run():
	print("Starting rig...")
	var base_scene = load("res://00083models/femWarrior/Characters/A03.FBX")
	if not base_scene:
		print("Failed to load base scene A03.FBX")
		return
		
	var root = base_scene.instantiate()
	var anim_player = root.get_node_or_null("AnimationPlayer")
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
		anim_player.owner = root
	
	var anim_lib = AnimationLibrary.new()
	var anim_files = {
		"idle": "res://00083models/femWarrior/RootAnimsFemale/BaseFemale@1HIdle.fbx",
		"walk": "res://00083models/femWarrior/RootAnimsFemale/BaseFemale@1HWalkF.fbx",
		"run": "res://00083models/femWarrior/RootAnimsFemale/BaseFemale@1HCombatRunF.fbx",
		"attack": "res://00083models/femWarrior/RootAnimsFemale/BaseFemale@1HAttack.fbx"
	}
	for anim_name in anim_files:
		var path = anim_files[anim_name]
		var anim_scene = load(path)
		if anim_scene:
			var inst = anim_scene.instantiate()
			var ap = inst.get_node_or_null("AnimationPlayer")
			if ap:
				var lib = ap.get_animation_library("")
				if lib and lib.has_animation("Root|Root|RootAction|RootAction"):
					var anim = lib.get_animation("Root|Root|RootAction|RootAction")
					anim_lib.add_animation(anim_name, anim.duplicate())
			inst.queue_free()
			
	anim_player.add_animation_library("", anim_lib)
	
	var anim_tree = AnimationTree.new()
	anim_tree.name = "AnimationTree"
	root.add_child(anim_tree)
	anim_tree.owner = root
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	
	var statemachine = AnimationNodeStateMachine.new()
	for state in ["idle", "walk", "run", "attack"]:
		var anim_node = AnimationNodeAnimation.new()
		anim_node.animation = state
		statemachine.add_node(state, anim_node)
		
	var add_trans = func(from, to, switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE, advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED):
		var trans = AnimationNodeStateMachineTransition.new()
		trans.switch_mode = switch_mode
		trans.advance_mode = advance_mode
		statemachine.add_transition(from, to, trans)

	add_trans.call("Start", "idle", AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE, AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO)
	add_trans.call("idle", "walk")
	add_trans.call("walk", "idle")
	add_trans.call("walk", "run")
	add_trans.call("run", "walk")
	add_trans.call("idle", "run")
	add_trans.call("run", "idle")
	add_trans.call("idle", "attack")
	add_trans.call("walk", "attack")
	add_trans.call("run", "attack")
	add_trans.call("attack", "idle", AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END, AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO)
	
	anim_tree.tree_root = statemachine
	anim_tree.active = true
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	
	DirAccess.make_dir_recursive_absolute("res://00010entities/player/models/")
	var err = ResourceSaver.save(packed_scene, "res://00010entities/player/models/fem_warrior.tscn")
	if err == OK:
		print("Successfully saved fem_warrior.tscn")
	else:
		print("Failed to save: ", err)
