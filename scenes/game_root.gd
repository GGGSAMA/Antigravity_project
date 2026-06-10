extends Node3D
#class_name GameRoot

@onready var level_container: Node3D = $LevelContainer
@onready var player: CharacterBody3D = $Player

var current_level_path: String = ""
var current_level_node: Node = null

func _ready() -> void:
	# On startup, load main.tscn as the default level
	load_level("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			load_level("res://main.tscn")
		elif event.keycode == KEY_F2:
			load_level("res://scenes/terrain_level.tscn")

# Load level helper (similar to switch_level but returns node)
func load_level(level_path: String, spawn_pos: Variant = null) -> void:
	# Clean up current level
	if current_level_node:
		current_level_node.queue_free()
		current_level_node = null
	
	# Load new level scene
	var level_scene = load(level_path)
	if not level_scene:
		push_error("Failed to load level scene: " + level_path)
		return
	
	current_level_path = level_path
	current_level_node = level_scene.instantiate()
	level_container.add_child(current_level_node)
	
	# Handle player positioning
	var target_pos = Vector3.ZERO
	var target_rot = Vector3.ZERO
	
	if spawn_pos is Vector3:
		target_pos = spawn_pos
	elif current_level_node.has_node("PlayerSpawn"):
		var spawn_node = current_level_node.get_node("PlayerSpawn") as Node3D
		if spawn_node:
			target_pos = spawn_node.global_position
			target_rot = spawn_node.global_rotation
	else:
		# Default fallback position matching original main.tscn transform
		target_pos = Vector3(7.902, 0.276, -9.652)
		target_rot = Vector3(0, deg_to_rad(-40.0), 0)
	
	# Set player position and rotation
	player.global_position = target_pos
	player.global_rotation = target_rot
	player.velocity = Vector3.ZERO
	
	# If player has camera, reset its camera look angles or physics
	if player.has_method("reset_look_angles"):
		player.call("reset_look_angles")
	
	print("[GameRoot] Loaded level: ", level_path, " spawned player at: ", target_pos)

# Public level switching interface
func switch_level(level_path: String, spawn_pos: Variant = null) -> void:
	load_level(level_path, spawn_pos)
