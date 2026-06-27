extends Resource
class_name WorldTile

## ------------------ 政治与主权 (Politics & Sovereignty) ------------------
## 宗门归属权（空字符串表示无主之地）
@export var owner_sect_id: String = ""
## 控制力/法阵压制力 (0.0 - 1.0)
@export var control_influence: float = 0.0

## ------------------ 自然与修仙属性 (Nature & Cultivation) ------------------
## 灵气浓度（基准为 1.0，洞天福地可达 5.0 甚至 10.0，决定打坐修炼速度、稀有草药刷新极值）
@export var qi_density: float = 1.0
## 五行地脉属性 (0: 无, 1: 金, 2: 木, 3: 水, 4: 火, 5: 土)
@export var leyline_element: int = 0
## 腐化度/煞气值（0.0 正常，1.0 极度邪恶/绝地，影响 Shader 渲染和魔修收益）
@export var corruption_level: float = 0.0
## 气运/天道赐福（极稀有，高气运地块容易挖出极品法宝或触发奇遇）
@export var fortune_level: float = 0.0

## ------------------ 生态与资源 (Ecology & Resources) ------------------
## 生态圈类型（用于生成不同模型，如 "forest", "desert", "volcano", "snow"）
@export var biome_type: String = "forest"
## 资源富集度（决定矿石/草药的密度，被过度开采会下降）
@export var resource_richness: float = 1.0

## ------------------ 时空法则 (Time Zone & Scaling) ------------------
## 当前区块的时间流速乘数 (1.0 = 大世界同步, 10.0 = 洞中方一日世上已千年)
@export var time_zone_scale: float = 1.0

## ------------------ 经济与开发 (Economy & Development) ------------------
## 开发度（宗门建了聚灵阵、药园后数值上升）
@export var development_level: int = 0
## 当前阵法等级（保护该地块不被轻易夺走）
@export var formation_level: int = 0

## ------------------ 物理产出锁死 (Ecology Absolute Limits) ------------------
## 本区块当前绝对存在的物品数量池 (e.g. {"herb_low": 5, "ore_iron": 120})
@export var ecology_inventory: Dictionary = {}
## 本区块的灵气承载上限 (e.g. {"herb_low": 10, "ore_iron": 200})
@export var ecology_capacity: Dictionary = {}
## 记录上次大规模刷新的绝对天数
@export var last_growth_day: int = 0

## 初始化方法，可用于快速生成世界
func _init(_biome: String = "forest", _qi: float = 1.0):
	biome_type = _biome
	qi_density = _qi

## 将核心数据打包存盘用
func to_dict() -> Dictionary:
	return {
		"o": owner_sect_id,
		"q": qi_density,
		"c": corruption_level,
		"r": resource_richness,
		"d": development_level,
		"f": formation_level,
		"l": leyline_element,
		"t": time_zone_scale,
		"ei": ecology_inventory,
		"ec": ecology_capacity,
		"lgd": last_growth_day
	}

## 从存档恢复数据
func from_dict(data: Dictionary) -> void:
	if data.has("o"): owner_sect_id = data["o"]
	if data.has("q"): qi_density = data["q"]
	if data.has("c"): corruption_level = data["c"]
	if data.has("r"): resource_richness = data["r"]
	if data.has("d"): development_level = data["d"]
	if data.has("f"): formation_level = data["f"]
	if data.has("l"): leyline_element = data["l"]
	if data.has("t"): time_zone_scale = data["t"]
	if data.has("ei"): ecology_inventory = data["ei"]
	if data.has("ec"): ecology_capacity = data["ec"]
	if data.has("lgd"): last_growth_day = data["lgd"]
