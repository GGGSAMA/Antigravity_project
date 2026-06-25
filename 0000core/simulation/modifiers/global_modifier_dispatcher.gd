class_name GlobalModifierDispatcher
extends RefCounted

# ==============================================================================
# 【全局天道法则修正器 (Global Modifier Dispatcher)】
# 职责：提供跨区块、跨实体的全局环境增益/减益。
# 场景：末法时代、灵气复苏、天下大旱、全域毒瘴等。
# ==============================================================================

static var modifiers: Dictionary = {
	"world_aura_density": 1.0,  # 默认天下灵气倍率为 1.0
	"world_danger_level": 1.0,  # 默认天下凶险程度 1.0
	"sect_growth_rate": 1.0     # 宗门发展倍率
}

static func set_modifier(key: String, value: float) -> void:
	modifiers[key] = value

static func get_modifier(key: String, default_value: float = 1.0) -> float:
	return modifiers.get(key, default_value)

# 模拟一个“末法时代”降临的接口
static func trigger_apocalypse() -> void:
	set_modifier("world_aura_density", 0.1)
	print("[天道法则] 末法时代降临，天下灵气枯竭！")
