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

# 人物属性字典 (Key: npc_id)
# 存储他们是谁，什么境界，什么性格
var npc_attributes: Dictionary = {}

# 稀疏关系字典 (Key1: npc_id, Key2: target_npc_id)
# 只有结仇或结缘的才在这里面
var relationships: Dictionary = {}

func _ready() -> void:
	print("[", Time.get_ticks_msec(), " ms] [SocialManager] 启动修仙界羁绊引擎...")
	_initialize_test_data()
	print("[", Time.get_ticks_msec(), " ms] [SocialManager] 数据图谱初始化完成")

# 初始化测试数据 (3个基础NPC)
func _initialize_test_data() -> void:
	# 1. 注册李逍遥
	register_npc("npc_li_xiaoyao", {
		"name": "李逍遥",
		"faction_name": "蜀山剑派",
		"alignment": 0, # 正道
		"cultivation": 2, # 筑基
		"personality_tags": ["嫉恶如仇", "剑痴"],
		"status": "游历中",
		"wealth": 500
	})
	
	# 2. 注册血老怪
	register_npc("npc_xue_laoguai", {
		"name": "血老怪",
		"faction_name": "万骨窟",
		"alignment": 1, # 魔道
		"cultivation": 3, # 金丹
		"personality_tags": ["残暴", "护短", "极度贪婪"],
		"status": "疗伤中",
		"wealth": 8000
	})
	
	# 3. 注册钱百万
	register_npc("npc_qian_baiwan", {
		"name": "钱百万",
		"faction_name": "四海商会",
		"alignment": 2, # 中立
		"cultivation": 1, # 炼气
		"personality_tags": ["和气生财", "极其圆滑", "胆小"],
		"status": "经营坊市",
		"wealth": 99999
	})
	
	# 建立稀疏网络关系 (手动设置一些初始剧本羁绊)
	
	# 李逍遥 极度仇恨 血老怪 (可能血老怪杀了他师弟)
	set_relationship("npc_li_xiaoyao", "npc_xue_laoguai", {
		"affinity": -80,
		"fear": 0, # 初生牛犊不怕虎
		"tags": ["血海深仇", "正邪不两立"],
		"history_logs": ["血老怪三年前屠灭了李逍遥的凡人村落。"]
	})
	
	# 血老怪 看不起 李逍遥
	set_relationship("npc_xue_laoguai", "npc_li_xiaoyao", {
		"affinity": -30,
		"fear": 0,
		"tags": ["蝼蚁", "正道伪君子"],
		"history_logs": ["随手捏死了一群凡人，跑了个小鬼天天喊着报仇，烦死了。"]
	})
	
	# 钱百万 对 李逍遥 (普通客户)
	set_relationship("npc_qian_baiwan", "npc_li_xiaoyao", {
		"affinity": 10,
		"fear": 0,
		"tags": ["潜在客户", "穷光蛋"],
		"history_logs": ["这穷酸剑修总来买最低级的凝气丹。"]
	})
	
	# 钱百万 对 血老怪 (害怕但要赚钱)
	set_relationship("npc_qian_baiwan", "npc_xue_laoguai", {
		"affinity": -10,
		"fear": 90, # 极其害怕被杀人夺宝
		"tags": ["危险的大客户", "不可招惹"],
		"history_logs": ["这老魔头上次买阵法材料差点动手抢，还好商会长老出面震慑住了。"]
	})

# ==============================================================================
# 操作接口 (Public API)
# ==============================================================================

# 注册一个新 NPC 到属性池
func register_npc(npc_id: String, attributes: Dictionary) -> void:
	npc_attributes[npc_id] = attributes

# 获取 NPC 属性
func get_npc(npc_id: String) -> Dictionary:
	return npc_attributes.get(npc_id, {})

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
