extends Node

const LOD_ACTIVE_DISTANCE: float = 150.0
const NPC_SCENE = preload("res://00030entities/npc/npc.tscn")

# 活跃池：存储在玩家附近的 NPC ID
var active_pool: Array[String] = []

# 背景池：存储离玩家较远，被挂起的 NPC ID
var background_pool: Array[String] = []

# 负责管理全局所有 NPC 数据的字典 (Key: npc_id, Value: CharacterData)
var global_npc_registry: Dictionary = {}

# 活跃节点的字典缓存，用于查找和销毁 (Key: npc_id, Value: Node3D)
var active_nodes: Dictionary = {}

func _ready() -> void:
	print("[LODManager] 初始化完成，启动空间折叠检测。")
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_check_lod)
	add_child(timer)

# 注册一个新生成的 NPC 到全局注册表
func register_npc(data: CharacterData) -> void:
	if not global_npc_registry.has(data.npc_id):
		global_npc_registry[data.npc_id] = data
		# 默认丢进背景池
		background_pool.append(data.npc_id)
		# 注册时立刻尝试距离检测，这样在玩家身边生成的NPC会瞬间刷新
		_check_single_npc_lod(data.npc_id)

func _get_player() -> Node3D:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_node_or_null("/root/GameRoot/Player")
	return player

func _on_check_lod() -> void:
	var player = _get_player()
	if not player: return
	var player_pos = player.global_position

	# 检查后台池，离得近的拉出来
	for i in range(background_pool.size() - 1, -1, -1):
		var npc_id = background_pool[i]
		if global_npc_registry.has(npc_id):
			var data = global_npc_registry[npc_id]
			if data.world_position.distance_to(player_pos) < LOD_ACTIVE_DISTANCE:
				promote_to_active(npc_id)

	# 检查活跃池，离得远的塞回去
	for i in range(active_pool.size() - 1, -1, -1):
		var npc_id = active_pool[i]
		if global_npc_registry.has(npc_id):
			var data = global_npc_registry[npc_id]
			# Hysteresis: 退出的距离比进入长50米，防止在边界反复刷新
			if data.world_position.distance_to(player_pos) > (LOD_ACTIVE_DISTANCE + 50.0):
				demote_to_background(npc_id)

func _check_single_npc_lod(npc_id: String) -> void:
	var player = _get_player()
	if not player: return
	if global_npc_registry.has(npc_id):
		var data = global_npc_registry[npc_id]
		if data.world_position.distance_to(player.global_position) < LOD_ACTIVE_DISTANCE:
			if background_pool.has(npc_id):
				promote_to_active(npc_id)

# 将 NPC 从背景池提升到活跃池 (波函数坍缩为物理)
func promote_to_active(npc_id: String) -> void:
	if background_pool.has(npc_id):
		background_pool.erase(npc_id)
		active_pool.append(npc_id)
		if global_npc_registry.has(npc_id):
			var data = global_npc_registry[npc_id]
			data.is_collapsed = true
			
			# === 真正的 3D 实例化逻辑 ===
			var scene_root = get_tree().current_scene
			if scene_root:
				var npc_instance = NPC_SCENE.instantiate()
				npc_instance.name = "NPC_" + npc_id
				scene_root.add_child(npc_instance)
				npc_instance.global_position = data.world_position
				
				# 同步数据绑定
				if npc_instance.has_method("setup_from_data"):
					npc_instance.setup_from_data(data)
					
				active_nodes[npc_id] = npc_instance
				print("[LODManager] 🌟 波函数坍缩！NPC (", data.npc_name, ") 实体化于 ", data.world_position)

# 将 NPC 从活跃池降级到背景池 (波函数发散为纯数据)
func demote_to_background(npc_id: String) -> void:
	if active_pool.has(npc_id):
		active_pool.erase(npc_id)
		background_pool.append(npc_id)
		if global_npc_registry.has(npc_id):
			var data = global_npc_registry[npc_id]
			data.is_collapsed = false
			
			# === 真实的 3D 回收逻辑 ===
			if active_nodes.has(npc_id):
				var npc_instance = active_nodes[npc_id]
				if is_instance_valid(npc_instance):
					# 将走动后的坐标写回字典保存
					data.world_position = npc_instance.global_position
					npc_instance.queue_free()
				active_nodes.erase(npc_id)
				print("[LODManager] 🌌 波函数发散。NPC (", data.npc_name, ") 被移入后台。")

# 获取属于特定区块的所有 NPC
func get_npcs_in_chunk(chunk_id: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for npc_id in global_npc_registry.keys():
		var data: CharacterData = global_npc_registry[npc_id]
		if data.current_location == chunk_id:
			result.append(data)
	return result
