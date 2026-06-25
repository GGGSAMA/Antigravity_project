# ==============================================================================
# 【妖兽数据源与底层架构 (MonsterDatabase)】
# ------------------------------------------------------------------------------
# 类说明：负责加载和缓存所有怪物的数据配置，支持以后从 JSON/CSV 动态加载，
# 包含妖兽的生命值、护甲、经验值(EXP)、掉落物和攻击力等数值。
# ==============================================================================

extends Node
class_name MonsterDatabase

# 运行时内存字典（动态加载的妖兽缓存）
static var MONSTERS: Dictionary[String, MonsterData] = {}

# --- 安全加载机制：懒加载外部配置文件 ---
static func _load_if_empty() -> void:
	if not MONSTERS.is_empty():
		return

	# 以后可以在这里增加 CSV/JSON 读取逻辑，目前直接加载兜底数据
	_load_fallback_monsters()

# --- 内置妖兽基础数据 (兜底) ---
static func _load_fallback_monsters() -> void:
	MONSTERS = {}
	
	var goblin = MonsterData.new(
		"goblin_weak", 
		"怯弱的小妖", 
		"res://00083models/characters/gdquest_sophia/sophia_skin.tscn", 
		50, 
		5, 
		0, 
		10, 
		[{"item_id": "小还丹", "chance": 0.2, "min_qty": 1, "max_qty": 1}]
	)
	MONSTERS["goblin_weak"] = goblin
	
	var wolf = MonsterData.new(
		"wolf_demon",
		"啸月狼妖",
		"res://00083models/characters/gdquest_sophia/sophia_skin.tscn",
		150,
		15,
		5,
		30,
		[{"item_id": "五毒散", "chance": 0.1, "min_qty": 1, "max_qty": 2}]
	)
	MONSTERS["wolf_demon"] = wolf
	
	var renegade = MonsterData.new(
		"sect_renegade",
		"弃宗魔修",
		"res://00083models/characters/gdquest_sophia/sophia_skin.tscn",
		300,
		35,
		10,
		100,
		[
			{"item_id": "聚灵散", "chance": 0.5, "min_qty": 1, "max_qty": 3},
			{"item_id": "千里传送令", "chance": 0.05, "min_qty": 1, "max_qty": 1}
		]
	)
	MONSTERS["sect_renegade"] = renegade
	
	print("【妖兽数据库】已启用系统内置妖兽配置！加载了 ", MONSTERS.size(), " 种妖兽。")

# --- 安全读取接口 API ---

# 获取某个妖兽的完整配置对象
static func get_monster(monster_id: String) -> MonsterData:
	_load_if_empty()
	if MONSTERS.has(monster_id):
		return MONSTERS[monster_id]

	# 如果找不到，返回一个弱鸡史莱姆兜底
	return MonsterData.new(
		"unknown",
		"未知弱小魔物",
		"res://00083models/characters/gdquest_sophia/sophia_skin.tscn",
		10,
		1,
		0,
		1,
		[]
	)
