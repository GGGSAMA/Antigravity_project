extends Resource
class_name CharacterData

# ================================
# 基础身份数据
# ================================
@export var npc_id: String = ""
@export var npc_name: String = "无名散修"
@export var faction_id: String = ""
@export var faction_role: String = "外门弟子"
@export var faction: FactionData
@export var is_alive: bool = true
@export var current_world_pos: Vector3 = Vector3.ZERO # 宏观空间坐标

# ================================
# 动态状态标签 (Dynamic Status Tags)
# ================================
@export var status_tags: Array[String] = []

func add_status_tag(tag: String) -> void:
	if not tag in status_tags:
		status_tags.append(tag)
		var eb = Engine.get_main_loop().root.get_node_or_null("EventBus")
		if eb and eb.has_signal("npc_status_changed"):
			eb.npc_status_changed.emit(npc_id, tag, true)

func remove_status_tag(tag: String) -> void:
	if tag in status_tags:
		status_tags.erase(tag)
		var eb = Engine.get_main_loop().root.get_node_or_null("EventBus")
		if eb and eb.has_signal("npc_status_changed"):
			eb.npc_status_changed.emit(npc_id, tag, false)

func has_status_tag(tag: String) -> bool:
	return tag in status_tags

# ================================
# 声望、业力与人际关系 (Reputation, Karma & Relationships)
# ================================
@export var fame: int = 0  # 名望 (正为正派大侠，负为魔道妖人)
@export var karma: int = 0 # 业力/功德 (正为功德，负为业力，影响雷劫和心魔)
@export var friends: Array[String] = [] # 好友/道侣 ID
@export var enemies: Array[String] = [] # 仇人 ID

# ================================
# 性格特质过滤器 (Trait Filter)
# ================================
@export var trait_cautious: int = 50   # 谨慎 (0-100)
@export var trait_ambition: int = 50   # 野心 (0-100)
@export var trait_greed: int = 50      # 贪婪 (0-100)
@export var trait_morality: int = 50   # 仁善 (0-100)
@export var trait_sociability: int = 50# 社交 (0-100)

# ================================
# 短期驱动力需求 (Needs)
# ================================
@export var need_cultivation: float = 100.0 # 修炼需求 (最核心)
@export var need_lifespan: float = 0.0      # 寿元需求 (快死时暴涨)
@export var need_healing: float = 0.0       # 疗伤需求 (重伤时暴涨)
@export var need_resource: float = 0.0      # 资源需求 (缺钱/缺材料)
@export var need_status: float = 0.0        # 地位需求 (争夺掌门/名望)

# ================================
# 长期人生目标 (Goals)
# ================================
@export var life_goal: String = "ASCEND" # 默认目标：飞升


# ================================
# 八大基础核心属性 (Core Stats)
# ================================
@export var stamina: int = 100       # 体力 (HP/物理抵抗)
@export var mana: int = 100          # 灵力 (MP/法力上限)
@export var comprehension: int = 50  # 悟性 (突破瓶颈、副职业经验倍率)
@export var aptitude: int = 50       # 资质 (核心：影响基准修炼速度 100XP/年的倍率)
@export var speed: int = 50          # 速度 (移动、闪避、出手速度)
@export var divine_sense: int = 50   # 神识 (侦查范围、精神抗性)
@export var state_of_mind: int = 100 # 心境 (情绪稳定度、走火入魔抗性)
@export var age: int = 16            # 骨龄
@export var max_lifespan: int = 100  # 寿命上限

# ================================
# 灵根系统 (Spiritual Roots) - 觅长生均分法则
# ================================
# 金、木、水、火、土的纯度 (0~100)。纯度越高、灵根属性越少，资质越高。
@export var spiritual_roots: Dictionary = {
	"metal": 20, "wood": 20, "water": 20, "fire": 20, "earth": 20
}

func generate_roots_by_hierarchy(target_realm: int, faction_elements: Array[String], is_rogue: bool = false) -> void:
	var elements = ["metal", "wood", "water", "fire", "earth"]
	for el in elements: spiritual_roots[el] = 0

	var root_count = 5
	var r = randf()

	# 根据境界分配灵根数量概率
	if target_realm >= 4: # 元婴及以上 (宗主/老怪)
		if r < 0.7: root_count = 1
		else: root_count = 2
	elif target_realm == 3: # 金丹 (长老)
		if r < 0.1: root_count = 1
		elif r < 0.8: root_count = 2
		else: root_count = 3
	elif target_realm == 2: # 筑基 (内门)
		if r < 0.2: root_count = 2
		elif r < 0.8: root_count = 3
		else: root_count = 4
	else: # 炼气 (外门/杂役)
		if r < 0.01: root_count = 1 # 极小概率气运之子
		elif r < 0.05: root_count = 2
		elif r < 0.2: root_count = 3
		elif r < 0.6: root_count = 4
		else: root_count = 5

	# 散修很容易是五灵根
	if is_rogue and target_realm <= 2 and randf() < 0.8:
		root_count = 5

	elements.shuffle()
	var active_roots = []

	# 强制宗门五行倾斜
	var guaranteed_element = ""
	if faction_elements.size() > 0 and not is_rogue:
		guaranteed_element = faction_elements[randi() % faction_elements.size()]
		active_roots.append(guaranteed_element)
		elements.erase(guaranteed_element)

	while active_roots.size() < root_count:
		var el = elements.pop_back()
		active_roots.append(el)

	# 均分 100，余数分配给前几个灵根（如果是宗门倾斜，必定分配给 guaranteed_element）
	var base_val = int(100 / root_count)
	var remainder = 100 % root_count

	for i in range(active_roots.size()):
		spiritual_roots[active_roots[i]] = base_val + (1 if i < remainder else 0)

	# 天灵根 100，五灵根 20。直接把单项最高纯度作为资质。
	var highest_purity = 0
	for val in spiritual_roots.values():
		if val > highest_purity: highest_purity = val
	aptitude = highest_purity

# --------------------------------
# 战斗数值挂载点 (Combat Hooks)
# --------------------------------
func get_elemental_multiplier(element_type: String) -> float:
	# 根据灵根纯度返回伤害倍率。如果是天灵根(100)，带来 2.0 倍伤害
	var purity = spiritual_roots.get(element_type, 0)
	return 1.0 + ((purity - 20) / 80.0)

func get_cooldown_reduction(element_type: String) -> float:
	# 灵根纯度越高，施法 CD 越短
	var purity = spiritual_roots.get(element_type, 0)
	# 纯度 20 -> 0% CD 减免，纯度 100 -> 50% CD 减免
	return clamp((purity - 20) / 160.0, 0.0, 0.5)

func get_mana_cost_reduction(element_type: String) -> float:
	# 灵根纯度影响耗蓝减免
	var purity = spiritual_roots.get(element_type, 0)
	return clamp((purity - 20) / 160.0, 0.0, 0.5) # 最多减半

func get_hp_regen_bonus() -> float:
	# 木灵根决定被动回血倍率
	var purity = spiritual_roots.get("wood", 0)
	return 1.0 + ((purity) / 50.0) # 纯度100 -> 3.0倍回血

func get_defense_bonus() -> float:
	# 土灵根决定护甲倍率
	var purity = spiritual_roots.get("earth", 0)
	return 1.0 + ((purity) / 50.0)


# ================================
# 境界与修为系统 (Cultivation Component)
# ================================
# 通过组件化将所有修为逻辑剥离，解决“数据独立”问题。
var cultivation_comp: CultivationComponent

# 综合战力 (由境界、属性、法宝等综合评估得出，用于纯数值比拼)
@export var combat_power: int = 10

# ================================
# 生活职业 (Life Skills)
# ================================
# 每一项包含: level (1=入门, 2=初级, 3=精通, 4=掌握, 5=大师), xp (当前经验)
@export var life_skills: Dictionary = {
	"alchemy": {"level": 1, "xp": 0.0},
	"smithing": {"level": 1, "xp": 0.0},
	"talisman": {"level": 1, "xp": 0.0}
}

# ================================
# NPC 经济与状态
# ================================
@export var current_action: String = "idle" 
@export var tags: Array[String] = [] # 泛用状态标签库（实现道伤、中毒、顿悟等一切组合架构的底层基础）
@export var money: int = 500 # 灵石
@export var inventory: Dictionary = {}



func _init() -> void:
	cultivation_comp = CultivationComponent.new()
	cultivation_comp._refresh_max_qi() # 强制初始化，因为不加入树无法调用 _ready

	# 连接修为组件的信号
	cultivation_comp.breakthrough_failed.connect(func(penalty): process_life_event("breakthrough_failed", {"penalty": penalty}))
	cultivation_comp.realm_advanced.connect(func(r, s): process_life_event("breakthrough_success", {}))
	# 随机赋予初始性格
	trait_cautious = randi_range(10, 90)
	trait_ambition = randi_range(10, 90)
	trait_greed = randi_range(10, 90)
	trait_morality = randi_range(10, 90)
	trait_sociability = randi_range(10, 90)

# ================================
# 空间加载与状态坍缩 (Spatial & LOD)
# ================================
func process_life_event(event_type: String, params: Dictionary) -> void:
	match event_type:
		"breakthrough_failed":
			if trait_cautious > 70:
				need_healing += 80.0
				need_cultivation = 0.0
				history_trajectory.append({"age": age, "text": "突破失败，生性谨慎，立刻决定闭门死守疗伤！", "level": 2})
			elif trait_ambition > 70:
				need_cultivation += 50.0
				history_trajectory.append({"age": age, "text": "天道不公！我命由我不由天，强行运转残破经脉继续修炼！", "level": 2})
			else:
				need_healing += 40.0

		"partner_died":
			if trait_morality > 70 and trait_sociability > 50:
				# 斩断常规需求，强制生成最高优先级复仇执念
				need_cultivation = 0.0
				need_resource += 100.0 # 需要买凶或买资源复仇
				history_trajectory.append({"age": age, "text": "道侣惨死，此仇不共戴天！杀！", "level": 3})
			elif trait_ambition > 80:
				cultivation_comp.add_qi(5000.0) 
				history_trajectory.append({"age": age, "text": "亲手斩断红尘羁绊，心境大圆满，修为暴涨。", "level": 3})

		"breakthrough_success":
			if trait_ambition > 60:
				need_cultivation += 20.0 # 继续疯狂修炼

var locked_days_remaining: int = 0
var history_trajectory: Array[Dictionary] = []

# ================================
# 空间加载与状态坍缩 (Spatial & LOD)
# ================================
@export var current_location: String = "未知区域"
@export var world_position: Vector3 = Vector3.ZERO
@export var is_collapsed: bool = false 

func decay_needs(days: int = 1) -> void:
	if not is_alive or is_collapsed: return
	# 暂时移除自然衰减，改由寿命和长期 Goal 驱动
	pass

# ================================
# 跨阶突破算法 (Breakthrough Logic) - 已转移至 CultivationComponent
# ================================

func _recalculate_combat_power() -> void:
	# 综合战力的粗略评估：境界基础 + 属性加成
	var realm = cultivation_comp.cultivation_realm
	var stage = cultivation_comp.cultivation_stage
	var base_power = 0
	if realm == 1: base_power = stage * 10
	elif realm == 2: base_power = 200 + stage * 100
	elif realm == 3: base_power = 1000 + stage * 500
	elif realm == 4: base_power = 5000 + stage * 2000

	# 属性加成占比
	var attr_bonus = (stamina + mana + speed + divine_sense) / 4.0
	combat_power = int(base_power + attr_bonus)

# 增加副职业经验
func add_life_skill_xp(skill_name: String, amount: float) -> void:
	if not life_skills.has(skill_name): return

	var data = life_skills[skill_name]
	if data["level"] >= 5: return # 已是大师

	data["xp"] += amount

	var thresholds = [0, 1000, 3000, 6000, 10000, 15000]
	var current_level = data["level"]
	var max_xp = thresholds[current_level]

	while data["xp"] >= max_xp and data["level"] < 5:
		data["xp"] -= max_xp
		data["level"] += 1
		current_level = data["level"]
		if current_level < 5:
			max_xp = thresholds[current_level]
		else:
			data["xp"] = 0 # 满级锁定
			break

		# 记录历史
		var level_names = ["初窥门径", "登堂入室", "融会贯通", "炉火纯青", "一代宗师"]
		var s_names = {"alchemy": "丹道", "smithing": "炼器", "talisman": "符箓"}
		history_trajectory.append({"age": age, "text": "%s技艺精进，达到了【%s】之境！" % [s_names.get(skill_name, skill_name), level_names[current_level-1]], "level": 2})
