extends Node

# 活跃池：存储在玩家附近的 NPC ID
var active_pool: Array[String] = []

# 背景池：存储离玩家较远，被挂起的 NPC ID
var background_pool: Array[String] = []

# 负责管理全局所有 NPC 数据的字典 (Key: npc_id, Value: CharacterData)
var global_npc_registry: Dictionary = {}

func _ready() -> void:
	print("[LODManager] 初始化完成。")

# 注册一个新生成的 NPC 到全局注册表
func register_npc(data: CharacterData) -> void:
	if not global_npc_registry.has(data.npc_id):
		global_npc_registry[data.npc_id] = data
		# 默认丢进背景池
		background_pool.append(data.npc_id)

# 将 NPC 从背景池提升到活跃池
func promote_to_active(npc_id: String) -> void:
	if background_pool.has(npc_id):
		background_pool.erase(npc_id)
		active_pool.append(npc_id)
		if global_npc_registry.has(npc_id):
			global_npc_registry[npc_id].is_collapsed = true

# 将 NPC 从活跃池降级到背景池
func demote_to_background(npc_id: String) -> void:
	if active_pool.has(npc_id):
		active_pool.erase(npc_id)
		background_pool.append(npc_id)
		if global_npc_registry.has(npc_id):
			global_npc_registry[npc_id].is_collapsed = false

# 获取属于特定区块的所有 NPC
func get_npcs_in_chunk(chunk_id: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for npc_id in global_npc_registry.keys():
		var data: CharacterData = global_npc_registry[npc_id]
		if data.current_location == chunk_id:
			result.append(data)
	return result
