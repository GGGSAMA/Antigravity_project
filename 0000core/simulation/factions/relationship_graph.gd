extends Node

# ==============================================================================
# 【社交关系图谱核心 (Relationship Graph)】
# 整体功能：
#   维护全修仙界所有实体（NPC/玩家）之间的长期社会关系边（Edges）。
# 状态设定：
#   - edges: 有向关系图字典 `edges[A][B] = [RelationTag, RelationTag]`
# 核心接口：
#   - add_relation(id_a, id_b, tag): 添加一条单向/双向关系边。
#   - get_relation_tags(id_a, id_b): 获取 A 对 B 的所有关系标签。
# 权重参数扩展说明：
#   - Tag 本身携带有 min_stance 和 max_stance 的钳制（Clamp）属性，用于社交推演覆写。
# ==============================================================================

# 定义态度层级枚举，分数越高态度越好
enum Stance {
	HOSTILE_GREEDY = 0, # 杀人夺宝 / 敌视
	DISDAIN = 1,        # 鄙夷 / 轻视
	NEUTRAL = 2,        # 路人 / 中立
	FRIENDLY = 3,       # 友善 / 交好
	FAWNING = 4         # 谄媚 / 敬畏
}

# 图数据结构：edges[from_id][to_id] = ["tag1", "tag2"]
var edges: Dictionary = {}

# 动态加载的标签资源库
# key: tag_id, value: RelationTagData
var tag_database: Dictionary = {}

func _ready():
	_load_tag_database()

# 扫描并加载所有配在文件里的 Tag 资源
func _load_tag_database():
	var dir_path = "res://0000core/simulation/data/relation_tags/"
	var dir = DirAccess.open(dir_path)
	if not dir:
		# 第一次运行如果没有目录，先建一个
		DirAccess.make_dir_recursive_absolute("res://0000core/simulation/data/relation_tags/")
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res = load(dir_path + file_name)
			if res is RelationTagData:
				tag_database[res.tag_id] = res
		file_name = dir.get_next()

# 添加有向关系（如果 is_bidirectional 为真，则自动加双向）
func add_relation(from_id: String, to_id: String, tag: String, is_bidirectional: bool = false) -> void:
	if not tag_database.has(tag):
		push_warning("试图添加未知关系标签 (可能是动态生成的或未配表): ", tag)
		# 即使没配表也允许添加，可能只是纯文本标记，没有钳制效果
		
	if not edges.has(from_id):
		edges[from_id] = {}
	if not edges[from_id].has(to_id):
		edges[from_id][to_id] = []
		
	if not tag in edges[from_id][to_id]:
		edges[from_id][to_id].append(tag)
		
	if is_bidirectional:
		add_relation(to_id, from_id, tag, false)

# 获取 A 对 B 的所有关系标签名称数组
func get_relation_tags(from_id: String, to_id: String) -> Array:
	if edges.has(from_id) and edges[from_id].has(to_id):
		return edges[from_id][to_id]
	return []

# 【核心功能】：汇总 A 对 B 所有的关系网标签，计算出钳制边界 (min_stance, max_stance)
func get_stance_clamp(from_id: String, to_id: String) -> Dictionary:
	var tags = get_relation_tags(from_id, to_id)
	if tags.is_empty():
		return {"has_clamp": false}
		
	var final_min = Stance.HOSTILE_GREEDY
	var final_max = Stance.FAWNING
	var has_clamp = false
	
	for t in tags:
		if tag_database.has(t):
			has_clamp = true
			var def = tag_database[t]
			if def.min_stance > final_min:
				final_min = def.min_stance
			if def.max_stance < final_max:
				final_max = def.max_stance
				
	# 冲突处理：如果 min 跑到 max 上面了（比如既是死敌又是道侣这种极端 Bug），以 max 为主
	if final_min > final_max:
		final_min = final_max
		
	return {
		"has_clamp": has_clamp,
		"min_stance": final_min,
		"max_stance": final_max
	}
