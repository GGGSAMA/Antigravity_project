# ==============================================================================
# GameRoot (全局场景调度与实体根节点)
# 
# [设计意图 / Design Intent]:
# 此脚本挂载于唯一根节点 GameRoot，是整个游戏世界的“主板”。
# 它负责协调全局场景切换 (Level Loading)、动态场景实例化、玩家实体控制权转移，
# 以及特殊独立副本（如随身小秘境）的内存驻留与来回穿梭。
#
# [架构职责 / Responsibilities]:
# 1. 拦截与管理所有 Level (Map) 的生命周期，确保安全的资源释放。
# 2. 负责玩家的无缝地图传输（Teleportation），并处理跨场景的坐标对接与地形安全着陆。
# 3. 隔离全局 UI，禁止 Level 内部实例化独立 UI（统一交由外部 UIStack 处理）。
# ==============================================================================
extends Node3D
class_name GameRoot

@onready var level_container: Node3D = $LevelContainer
@onready var player: CharacterBody3D = $Player

var current_level_path: String = ""
var current_level_node: Node = null

# V0.0008.1: 随身小秘境后台常驻实体
var mystic_realm_instance: Node3D = null
var player_world_position: Vector3 = Vector3.ZERO
var player_world_rotation: Vector3 = Vector3.ZERO
var in_mystic_realm: bool = false

func _ready() -> void:
	# On startup, load main.tscn as the default level
	load_level("res://main.tscn")

## 加载并切换到目标关卡场景
## @param level_path: 场景 (.tscn) 资源的绝对路径
## @param spawn_pos: (可选) 加载场景后，玩家被安放的指定全局坐标 Vector3
func load_level(level_path: String, spawn_pos: Variant = null) -> void:
	# Clean up current level
	if current_level_node:
		current_level_node.queue_free()
		current_level_node = null
		
	# Broadcast global reset before loading the new level
	if EventBus and EventBus.has_signal("level_changing"):
		EventBus.emit_signal("level_changing")
	elif has_node("/root/EventBus"):
		get_node("/root/EventBus").emit_signal("level_changing")

	# Load new level scene
	var level_scene = load(level_path)
	if not level_scene:
		push_error("Failed to load level scene: " + level_path)
		return

	current_level_path = level_path
	current_level_node = level_scene.instantiate()
	level_container.add_child(current_level_node)

	# 强制剥夺地图场景中带有的所有幽灵 UI 拦截权
	_disable_level_ui(current_level_node)

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
	_position_player_safely(target_pos, target_rot, level_path)

func _disable_level_ui(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_level_ui(child)

## 安全安放玩家实体，确保不会穿模掉入虚空或卡在地下
## @param target_pos: 期望的理论安放坐标
## @param target_rot: 期望的视线朝向
## @param level_path: 当前所在场景路径（用于特定逻辑判定）
## @description:
## 为了解决刚加载完场景时物理引擎尚未生成 CollisionShape 的“活埋” Bug，
## 此函数优先绕开物理引擎，直接读取 Terrain3D 内存高度图进行绝对坐标锚定。
## 若不存在地形，则退化为短时间的高空物理射线轮询机制。
func _position_player_safely(target_pos: Vector3, target_rot: Vector3, level_path: String = "") -> void:
	# 取消禁用 process_mode！如果禁用，玩家体内的 Camera3D 也会停止工作，
	# 导致 Terrain3D 永远不会在该区域生成碰撞网格，从而卡死 10 秒！
	player.global_rotation = target_rot
	player.velocity = Vector3.ZERO

	if player.has_method("reset_look_angles"):
		player.call("reset_look_angles")

	# 先把玩家强行悬停在高空，防止相机穿模到地下很深的地方
	var hover_y = target_pos.y
	if hover_y < 10.0:
		hover_y = 100.0
	
	player.global_position = Vector3(target_pos.x, hover_y, target_pos.z)

	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(target_pos.x, 1000.0, target_pos.z),
		Vector3(target_pos.x, -1000.0, target_pos.z)
	)
	
	# 持续轮询，直到打到物理地面 (最多等待 10 秒)
	var max_wait_time = 10.0
	var time_waited = 0.0
	var safe_y = hover_y
	var hit_ground = false

	print("[GameRoot] 玩家进入悬停保护模式，等待地形物理网格加载...")
	
	while time_waited < max_wait_time:
		# 每一帧强行把玩家锁在空中，这样能保持 Camera3D 活跃，促使地形生成，同时防止玩家掉落
		player.global_position = Vector3(target_pos.x, hover_y, target_pos.z)
		player.velocity = Vector3.ZERO
		
		var result = space_state.intersect_ray(query)
		# 确保打到的是真实存在的物体，而不是什么奇怪的极低坐标
		if result and result.position.y > -900.0:
			safe_y = result.position.y + 0.5 # 贴地，留一点余量防止脚垫卡住
			hit_ground = true
			print("[GameRoot] Safe spawn raycast hit floor at: ", result.position, " after ", time_waited, "s")
			break
			
		await get_tree().physics_frame
		time_waited += get_process_delta_time()

	if not hit_ground:
		print("[GameRoot] Warning: 10秒超时，地形物理仍未加载，强制降落")
		if has_node("/root/Log"): get_node("/root/Log").info("GameRoot", "Safe spawn raycast missed! Using default pos.")

	# 最终安置玩家
	var final_pos = Vector3(target_pos.x, safe_y, target_pos.z)
	player.global_position = final_pos
	
	_spawn_fbx_test_nodes(current_level_node, final_pos)
	if level_path == "res://main.tscn":
		_spawn_test_npcs(final_pos)

	player.velocity = Vector3.ZERO
	print("[GameRoot] Loaded level: ", current_level_path, " spawned player at: ", player.global_position)



func _spawn_fbx_test_nodes(level_node: Node, player_pos: Vector3) -> void:
	# Spawn Rogue character model (bind pose)
	var rogue_path = "res://00042world/fbx/rogue_all.fbx"
	if ResourceLoader.exists(rogue_path):
		var rogue_scene = load(rogue_path)
		if rogue_scene:
			var rogue = rogue_scene.instantiate() as Node3D
			rogue.name = "Test_Rogue_FBX"
			level_node.add_child(rogue)
			# Position it 4 meters ahead and 2 meters to the left
			rogue.global_position = player_pos + Vector3(-2.0, 0.0, -4.0)
			print("[GameRoot] Spawned test Rogue FBX at: ", rogue.global_position)

	# Spawn Grass environment prop
	var grass_path = "res://00042world/fbx/SM_ENV_PLANT_grass_village.fbx"
	if ResourceLoader.exists(grass_path):
		var grass_scene = load(grass_path)
		if grass_scene:
			var grass = grass_scene.instantiate() as Node3D
			grass.name = "Test_Grass_FBX"
			level_node.add_child(grass)
			# Position it 4 meters ahead and 2 meters to the right
			grass.global_position = player_pos + Vector3(2.0, 0.0, -4.0)
			print("[GameRoot] Spawned test Grass FBX at: ", grass.global_position)

# Public level switching interface
func switch_level(level_path: String, spawn_pos: Variant = null) -> void:
	load_level(level_path, spawn_pos)

func _spawn_test_npcs(player_pos: Vector3) -> void:
	var npc_scene = load("res://00030entities/npc/npc.tscn")
	if not npc_scene:
		print("[GameRoot] Error: Failed to load npc.tscn")
		return

	# Spawn NPC 1: Active Hostile AI (12 meters in front of player spawn)
	var npc_hostile = npc_scene.instantiate()
	npc_hostile.name = "Hostile_NPC_Enemy"
	npc_hostile.is_passive = false
	current_level_node.add_child(npc_hostile)
	npc_hostile.global_position = player_pos + Vector3(0.0, 0.0, -12.0)
	print("[GameRoot] Spawned active hostile NPC at: ", npc_hostile.global_position)

	# Spawn NPC 2: Passive Sandbag Dummy (12 meters to the right of player spawn)
	var npc_passive = npc_scene.instantiate()
	npc_passive.name = "Passive_Training_Dummy"
	npc_passive.is_passive = true
	current_level_node.add_child(npc_passive)
	npc_passive.global_position = player_pos + Vector3(12.0, 0.0, 0.0)
	print("[GameRoot] Spawned passive training dummy at: ", npc_passive.global_position)
	
	# Spawn Test Loot Chest
	var chest_scene = load("res://00042world/facilities/loot_chest.tscn")
	if chest_scene:
		var chest = chest_scene.instantiate()
		current_level_node.add_child(chest)
		chest.global_position = player_pos + Vector3(2.0, 0.0, -2.0)
		print("[GameRoot] Spawned test LootChest at: ", chest.global_position)

# ==============================================================================
# 【随身小秘境/洞天双向传送逻辑】
# ==============================================================================
func get_or_create_mystic_realm() -> Vector3:
	if not mystic_realm_instance:
		print("[GameRoot] 首次加载并生成随身小秘境 (Y=2000)...")
		var realm_scene = load("res://00041scenes/mystic_realm/mystic_realm_room.tscn")
		if realm_scene:
			mystic_realm_instance = realm_scene.instantiate() as Node3D
			mystic_realm_instance.name = "MysticRealmRoom"
			# 设置到高空 (Y=2000)，避免超过单精度浮点数限制导致物理抖动
			mystic_realm_instance.global_position = Vector3(0, 2000, 0)
			# 挂载到 GameRoot，但不替换 current_level_node
			add_child(mystic_realm_instance)
		else:
			push_error("[GameRoot] 无法加载小秘境场景 res://00041scenes/mystic_realm/mystic_realm_room.tscn")
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
