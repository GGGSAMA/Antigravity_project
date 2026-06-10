extends Node3D
class_name GameRoot

@onready var level_container: Node3D = $LevelContainer
@onready var player: CharacterBody3D = $Player

var current_level_path: String = ""
var current_level_node: Node = null

# V0.0008.1: 随身小秘境后台常驻实例
var mystic_realm_instance: Node3D = null

func _ready() -> void:
	# On startup, load main.tscn as the default level
	load_level("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			load_level("res://main.tscn")
		elif event.keycode == KEY_F2:
			load_level("res://world/maps/terrain_level.tscn")

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
	
	# Spawn test FBX models dynamically near player
	_spawn_fbx_test_nodes(current_level_node, target_pos)
	
	# V0.0008: Spawn test NPCs dynamically to avoid modifying 26MB main.tscn
	if level_path == "res://main.tscn":
		_spawn_test_npcs(target_pos)
		







func _spawn_fbx_test_nodes(level_node: Node, player_pos: Vector3) -> void:
	# Spawn Rogue character model (bind pose)
	var rogue_scene = load("res://fbx/rogue_all.fbx")
	if rogue_scene:
		var rogue = rogue_scene.instantiate() as Node3D
		rogue.name = "Test_Rogue_FBX"
		# Position it 4 meters ahead and 2 meters to the left
		rogue.global_position = player_pos + Vector3(-2.0, 0.0, -4.0)
		level_node.add_child(rogue)
		print("[GameRoot] Spawned test Rogue FBX at: ", rogue.global_position)
		
	# Spawn Grass environment prop
	var grass_scene = load("res://fbx/SM_ENV_PLANT_grass_village.fbx")
	if grass_scene:
		var grass = grass_scene.instantiate() as Node3D
		grass.name = "Test_Grass_FBX"
		# Position it 4 meters ahead and 2 meters to the right
		grass.global_position = player_pos + Vector3(2.0, 0.0, -4.0)
		level_node.add_child(grass)
		print("[GameRoot] Spawned test Grass FBX at: ", grass.global_position)

# Public level switching interface
func switch_level(level_path: String, spawn_pos: Variant = null) -> void:
	load_level(level_path, spawn_pos)

func _spawn_test_npcs(player_pos: Vector3) -> void:
	var npc_scene = load("res://entities/npc/npc_base.tscn")
	if not npc_scene:
		print("[GameRoot] Error: Failed to load npc_base.tscn")
		return
		
	# Spawn NPC 1: Active Hostile AI (12 meters in front of player spawn)
	var npc_hostile = npc_scene.instantiate()
	npc_hostile.name = "Hostile_NPC_Enemy"
	npc_hostile.is_passive = false
	npc_hostile.global_position = player_pos + Vector3(0.0, 0.0, -12.0)
	current_level_node.add_child(npc_hostile)
	print("[GameRoot] Spawned active hostile NPC at: ", npc_hostile.global_position)
	
	# Spawn NPC 2: Passive Sandbag Dummy (12 meters to the right of player spawn)
	var npc_passive = npc_scene.instantiate()
	npc_passive.name = "Passive_Training_Dummy"
	npc_passive.is_passive = true
	npc_passive.global_position = player_pos + Vector3(12.0, 0.0, 0.0)
	current_level_node.add_child(npc_passive)
	print("[GameRoot] Spawned passive training dummy at: ", npc_passive.global_position)

# ==============================================================================
# 【随身小秘境/洞天双向传送逻辑】
# ==============================================================================
func get_or_create_mystic_realm() -> Vector3:
	if not mystic_realm_instance:
		print("[GameRoot] 首次加载并生成随身小秘境 (Y=5000)...")
		var realm_scene = load("res://world/maps/mystic_realm/mystic_realm_room.tscn")
		if realm_scene:
			mystic_realm_instance = realm_scene.instantiate() as Node3D
			mystic_realm_instance.name = "MysticRealmRoom"
			# 设置到极高空，避免与超大规模的大世界地形 (HTerrain) 发生视觉重叠
			mystic_realm_instance.global_position = Vector3(0, 50000, 0)
			# 挂载到 GameRoot，但不替换 current_level_node
			add_child(mystic_realm_instance)
		else:
			push_error("[GameRoot] 无法加载小秘境场景 res://world/maps/mystic_realm/mystic_realm_room.tscn")
			return Vector3(0, 50000, 0)
			
	var spawn_point = mystic_realm_instance.get_node("TeleportSpawnPoint") as Marker3D
	if spawn_point:
		return spawn_point.global_position
	else:
		return mystic_realm_instance.global_position + Vector3(0, 0.2, 0)
