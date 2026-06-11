extends Node3D
class_name GameRoot

@onready var level_container: Node3D = $LevelContainer
@onready var player: CharacterBody3D = $Player

var current_level_path: String = ""
var current_level_node: Node = null

# V0.0008.1: 随身小秘境后台常驻实例
var mystic_realm_instance: Node3D = null
var player_world_position: Vector3 = Vector3.ZERO
var player_world_rotation: Vector3 = Vector3.ZERO
var in_mystic_realm: bool = false

func _ready() -> void:
	# On startup, load main.tscn as the default level
	load_level("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			load_level("res://main.tscn")
		elif event.keycode == KEY_F2:
			load_level("res://world/maps/terrain_level.tscn")
		elif event.keycode == KEY_F3:
			if in_mystic_realm:
				exit_mystic_realm()
			else:
				enter_mystic_realm()

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
			# 微调 Y 轴高度，避免卡在地下，但也不要从太高的天上掉下来
			target_pos.y += 10.0
	else:
		# Default fallback position matching original main.tscn transform
		target_pos = Vector3(7.902, 50.0, -9.652)
		target_rot = Vector3(0, deg_to_rad(-40.0), 0)
	
	# Trigger the safe positioning coroutine
	_position_player_safely(target_pos, target_rot)
	
	# Spawn test FBX models dynamically near player
	_spawn_fbx_test_nodes(current_level_node, target_pos)
	
	# V0.0008: Spawn test NPCs dynamically to avoid modifying 26MB main.tscn
	if level_path == "res://main.tscn":
		_spawn_test_npcs(target_pos)

func _position_player_safely(target_pos: Vector3, target_rot: Vector3) -> void:
	# 暂时把玩家拉高并禁用物理，等待 Terrain3D 异步生成碰撞体
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(target_pos.x, target_pos.y + 1000.0, target_pos.z)
	player.global_rotation = target_rot
	player.velocity = Vector3.ZERO
	
	if player.has_method("reset_look_angles"):
		player.call("reset_look_angles")
	
	# 动态轮询等待 Terrain3D 碰撞体生成（避免固定卡顿 1.5s）
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(target_pos.x, target_pos.y + 1000.0, target_pos.z),
		Vector3(target_pos.x, -500.0, target_pos.z)
	)
	
	var max_wait_time = 3.0
	var time_waited = 0.0
	var result = {}
	
	while time_waited < max_wait_time:
		result = space_state.intersect_ray(query)
		if result:
			break
		# 等待一帧
		await get_tree().physics_frame
		time_waited += get_process_delta_time()
	
	if result:
		player.global_position = result.position + Vector3(0, 1.0, 0)
		print("[GameRoot] Safe spawn raycast hit terrain at: ", result.position, " after ", time_waited, "s")
	else:
		player.global_position = target_pos
		print("[GameRoot] Safe spawn raycast missed! Using default pos: ", target_pos)
		
	# 恢复物理
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.velocity = Vector3.ZERO
	print("[GameRoot] Loaded level: ", current_level_path, " spawned player at: ", player.global_position)
	
	

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
		print("[GameRoot] 首次加载并生成随身小秘境 (Y=2000)...")
		var realm_scene = load("res://world/maps/mystic_realm/mystic_realm_room.tscn")
		if realm_scene:
			mystic_realm_instance = realm_scene.instantiate() as Node3D
			mystic_realm_instance.name = "MysticRealmRoom"
			# 设置到高空 (Y=2000)，避免超过单精度浮点数限制导致物理抖动
			mystic_realm_instance.global_position = Vector3(0, 2000, 0)
			# 挂载到 GameRoot，但不替换 current_level_node
			add_child(mystic_realm_instance)
		else:
			push_error("[GameRoot] 无法加载小秘境场景 res://world/maps/mystic_realm/mystic_realm_room.tscn")
			return Vector3(0, 2000, 0)
			
	var spawn_point = mystic_realm_instance.get_node("TeleportSpawnPoint") as Marker3D
	if spawn_point:
		return spawn_point.global_position
	else:
		return mystic_realm_instance.global_position + Vector3(0, 0.2, 0)

func enter_mystic_realm(realm_id: String = "mystic_realm_room") -> void:
	if in_mystic_realm:
		print("[GameRoot] 已经在秘境中，无法重复进入。")
		return
		
	# 记录大世界坐标与朝向
	player_world_position = player.global_position
	player_world_rotation = player.global_rotation
	
	# 暂时禁用物理防止掉落
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.velocity = Vector3.ZERO
	
	var target_pos = get_or_create_mystic_realm()
	
	# 瞬间传送
	player.global_position = target_pos
	player.global_rotation = Vector3.ZERO
	in_mystic_realm = true
	print("[GameRoot] 🌀 传送进入秘境！原大世界坐标已保存: ", player_world_position)
	
	# 给 CSG 碰撞体一点点生成时间
	await get_tree().create_timer(0.2).timeout
	player.process_mode = Node.PROCESS_MODE_INHERIT

func exit_mystic_realm() -> void:
	if not in_mystic_realm:
		return
		
	# 原路折返
	player.global_position = player_world_position
	player.global_rotation = player_world_rotation
	player.velocity = Vector3.ZERO
	in_mystic_realm = false
	print("[GameRoot] 🌀 离开秘境！已返回大世界坐标: ", player_world_position)
