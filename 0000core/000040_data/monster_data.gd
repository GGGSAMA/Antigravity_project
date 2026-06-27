class_name MonsterData
extends Resource

# ==============================================================================
# 【强类型资源：妖兽数据实体 (MonsterData)】
# ==============================================================================

@export var id: String = ""
@export var name: String = "未知妖兽"
@export var model_path: String = ""
@export var max_health: int = 50
@export var attack_damage: int = 5
@export var defense: int = 0
@export var exp_yield: int = 10
@export var drop_table: Array = []

func _init(
	p_id: String = "",
	p_name: String = "未知妖兽",
	p_model_path: String = "",
	p_max_health: int = 50,
	p_attack_damage: int = 5,
	p_defense: int = 0,
	p_exp_yield: int = 10,
	p_drop_table: Array = []
):
	id = p_id
	name = p_name
	model_path = p_model_path
	max_health = p_max_health
	attack_damage = p_attack_damage
	defense = p_defense
	exp_yield = p_exp_yield
	drop_table = p_drop_table
