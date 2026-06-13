extends Node3D

@export var build_on_ready: bool = true

@onready var animation_tree: AnimationTree = null

func _ready():
	if build_on_ready:
		build_model()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var s = _find_skeleton(child)
		if s: return s
	return null

func build_model():
	print("Dynamically building fem_warrior model...")
	
	var base_scene = load("res://models/femWarrior/Characters/A03.FBX")
	if not base_scene:
		print("Failed to load base scene A03.FBX")
		return
		
	var root = base_scene.instantiate()
	add_child(root)
	
	var anim_player = root.get_node_or_null("AnimationPlayer")
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
	
	var skeleton = _find_skeleton(root)
	var skel_path: String = ""
	if skeleton and anim_player:
		skel_path = str(anim_player.get_node(anim_player.root_node).get_path_to(skeleton))
	
	var anim_lib = AnimationLibrary.new()
	
	var anim_files = {
		"idle": "res://models/femWarrior/RootAnimsFemale/BaseFemale@1HIdle.fbx",
		"walk": "res://models/femWarrior/RootAnimsFemale/BaseFemale@1HWalkF.fbx",
		"run": "res://models/femWarrior/RootAnimsFemale/BaseFemale@1HCombatRunF.fbx",
		"attack": "res://models/femWarrior/RootAnimsFemale/BaseFemale@1HAttack.fbx"
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
					var anim = lib.get_animation("Root|Root|RootAction|RootAction").duplicate()
					if anim_name in ["idle", "walk", "run"]:
						anim.loop_mode = Animation.LOOP_LINEAR
						
					if skel_path != "":
						for t in range(anim.get_track_count()):
							var path_str = str(anim.track_get_path(t))
							var parts = path_str.split(":")
							if parts.size() > 1:
								anim.track_set_path(t, NodePath(str(skel_path) + ":" + parts[1]))
								
					anim_lib.add_animation(anim_name, anim)
				else:
					if lib:
						var anim_list = lib.get_animation_list()
						for a in anim_list:
							var anim = lib.get_animation(a).duplicate()
							if anim_name in ["idle", "walk", "run"]:
								anim.loop_mode = Animation.LOOP_LINEAR
								
							if skel_path != "":
								for t in range(anim.get_track_count()):
									var path_str = str(anim.track_get_path(t))
									var parts = path_str.split(":")
									if parts.size() > 1:
										anim.track_set_path(t, NodePath(str(skel_path) + ":" + parts[1]))
										
							anim_lib.add_animation(anim_name, anim)
							break
			inst.queue_free()
			
	anim_player.add_animation_library("", anim_lib)
	
	var anim_tree = AnimationTree.new()
	anim_tree.name = "AnimationTree"
	root.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	
	var statemachine = AnimationNodeStateMachine.new()
	
	for state in ["idle", "walk", "run", "attack"]:
		var anim_node = AnimationNodeAnimation.new()
		anim_node.animation = state
		statemachine.add_node(state, anim_node)
		
	# Transitions
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
	
	self.animation_tree = anim_tree

func set_animation_state(state: String):
	if animation_tree and animation_tree.get("parameters/playback"):
		var playback = animation_tree.get("parameters/playback")
		playback.travel(state)
