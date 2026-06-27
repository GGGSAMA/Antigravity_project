extends Resource
class_name FactionData

# ==================================================================
# 宗门/势力 四维数据分离架构 (Civilization-style Faction ECS)
# ==================================================================

# 1. 地缘先天属性 (FactionGeoAttr)
class FactionGeoAttr extends Resource:
	@export var origin_terrain_type: String = "plains" # 地形类型：volcano, swamp, mountain
	@export var main_element: String = "earth"         # 地缘赋予的先天主五行
	@export var sub_element: String = "metal"          # 地缘次五行
	@export var geo_buff: Dictionary = {}              # 先天地形 Buff（如：炼丹产出+20%）

# 2. 功法发展偏向 (FactionCultureAttr)
class FactionCultureAttr extends Resource:
	@export var alchemy_weight: float = 1.0     # 炼丹偏好
	@export var smithing_weight: float = 1.0    # 炼器偏好
	@export var formation_weight: float = 1.0   # 阵法偏好
	@export var sword_weight: float = 1.0       # 剑修偏好
	@export var global_buffs: Dictionary = {}   # 辐射全宗门的 Buff
	@export var traits: Array[String] = []      # 宗门特质标签

# 3. 势力动态推演数值 (FactionPowerAttr)
class FactionPowerAttr extends Resource:
	@export var resource_reserves: int = 1000   # 灵石/物资储备
	@export var max_population: int = 50        # 弟子上限
	@export var current_population: int = 0     # 当前人口
	@export var diplomacy_matrix: Dictionary = {} # 外交红绿灯 (key: faction_id, val: 好感度)
	@export var total_combat_power: int = 100   # 宗门总战力评估

# 4. 宗门建筑与生息模板 (FactionBuildingAttr)
class FactionBuildingAttr extends Resource:
	# key: 建筑类型 (如 "alchemy_lab"), value: 等级
	@export var buildings: Dictionary = {}
	# 允许孵化的职业倾向配置池
	@export var spawn_rules: Dictionary = {}
	# 实体节点数据记录 (位置, 旋转等)
	@export var building_nodes: Array[Dictionary] = []

# ==================================================================
# 实例持有区 与 兼容旧版参数
# ==================================================================
@export var faction_id: String = ""
@export var faction_name: String = "未命名宗门"

@export var geo: FactionGeoAttr = FactionGeoAttr.new()
@export var culture: FactionCultureAttr = FactionCultureAttr.new()
@export var power: FactionPowerAttr = FactionPowerAttr.new()
@export var building: FactionBuildingAttr = FactionBuildingAttr.new()

# --- 旧版系统兼容保留字段 ---
@export var alignment: int = 0 # 0: 正道, 1: 魔道, 2: 中立
@export var level: int = 1     # 1: 草创期, 2: 立足期, 3: 争霸期
@export var core_world_pos: Vector3 = Vector3.ZERO
@export var territory_radius: float = 64.0
@export var members: Array[String] = []
@export var task_pool: Array[Dictionary] = []
