extends Node

# ==============================================================================
# 【社会关系与羁绊系统 (Social Manager)】
# ------------------------------------------------------------------------------
# 核心架构：稀疏网状图 (Sparse Graph) + 多维词条属性 (Multi-dimensional Tags)
# 职责：
# 1. 存储全服（哪怕上千个）NPC 的基础社会面板 (npc_attributes)。
# 2. 存储发生过交互的 NPC 之间的关系网 (relationships)。如果不认识，则内存里不存在该连线。
# 3. 提供极速查询接口，供 UI 和 NPC 行为树（AI）调用。
# 4. 未来供后台“因果事件引擎”跑日志运算。
# ==============================================================================

const CharacterData = preload("res://0000core/000010_simulation/entities/character_data.gd")
const FactionData = preload("res://0000core/000010_simulation/factions/faction_data.gd")

# 人物属性字典 (Key: npc_id)
# 存储他们是谁，什么境界，什么性格
var npc_attributes: Dictionary = {}

# 稀疏关系字典 (Key1: npc_id, Key2: target_npc_id)
# 只有结仇或结缘的才在这里面
var relationships: Dictionary = {}

func _ready() -> void:
	print("[", Time.get_ticks_msec(), " ms] [SocialManager] 启动修仙界羁绊引擎...")
	if EventBus and EventBus.has_signal("level_changing"):
		EventBus.level_changing.connect(reset_state)

func reset_state() -> void:
	npc_attributes.clear()
	relationships.clear()
	print("[SocialManager] 状态已重置")

	# 控制层调度 (Dispatch)
	var npc_gen = get_node_or_null("NPCGenerator")
	if npc_gen and npc_gen.has_method("generate_test_data"):
		npc_gen.generate_test_data()

	var relation_engine = get_node_or_null("RelationEngine")
	if relation_engine and relation_engine.has_method("build_initial_relations"):
		relation_engine.build_initial_relations()

	print("[", Time.get_ticks_msec(), " ms] [SocialManager] 数据图谱调度与初始化完成")

# ==============================================================================
# 数据查询接口 (Public API)
# ==============================================================================

# 获取 NPC 属性
func get_npc(npc_id: String) -> CharacterData:
	return npc_attributes.get(npc_id, null)

# 设置/覆盖两人之间的单向关系
func set_relationship(source_id: String, target_id: String, relation_data: Dictionary) -> void:
	if not relationships.has(source_id):
		relationships[source_id] = {}
	relationships[source_id][target_id] = relation_data

# 获取两人之间的单向关系
func get_relationship(source_id: String, target_id: String) -> Dictionary:
	if relationships.has(source_id) and relationships[source_id].has(target_id):
		return relationships[source_id][target_id]
	return {} # 如果没有交集，返回空（即默认陌生人）

# ==============================================================================
# 空间拓扑与扫描 (Spatial Topology)
# ==============================================================================

# 扫描半径内的目标实体（支持简单类型过滤）
# filter_type: "npc", "sect", "market" (后续可扩展)
func get_entities_in_radius(pos: Vector3, radius: float, filter_type: String = "npc") -> Array:
	var results = []
	var sq_radius = radius * radius

	if filter_type == "npc":
		for id in npc_attributes:
			var data = npc_attributes[id]
			if data is CharacterData and data.is_alive:
				var dist_sq = pos.distance_squared_to(data.current_world_pos)
				if dist_sq <= sq_radius:
					results.append(data)

	elif filter_type == "sect":
		var fm = get_node_or_null("/root/FactionManager")
		if fm and "active_factions" in fm:
			for f_id in fm.active_factions:
				var f_data = fm.active_factions[f_id]
				if "core_world_pos" in f_data:
					var dist_sq = pos.distance_squared_to(f_data.core_world_pos)
					if dist_sq <= sq_radius:
						results.append(f_data)

	return results
