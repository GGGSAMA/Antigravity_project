class_name SpellData
extends GameData

# ==============================================================================
# 【法术数据资源 (SpellData)】
# 替代原生的 Dictionary，提供强类型的属性调用和自动补全。
# ==============================================================================

@export var mana_cost: int = 0
@export var cast_time: float = 0.0
@export var cooldown: float = 0.0
@export var base_damage: int = 0
@export var effect_type: String = ""
@export var cast_range: float = 0.0
@export var aoe_radius: float = 0.0
@export var projectile_speed: float = 0.0
@export var is_continuous: bool = false
