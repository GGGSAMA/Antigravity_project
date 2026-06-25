extends Node
class_name CombatRuntimeAttr

signal health_changed(current_health: int, max_health: int)
signal mana_changed(current_mana: int, max_mana: int)

var current_health: int = 100
var max_health: int = 100
var current_mana: int = 100
var max_mana: int = 100

# 从 RootGenAttr 拿到的缓存倍率
var cached_multipliers: Dictionary = {}

func _ready() -> void:
	var root_gen = get_parent().get_node_or_null("RootGenAttr")
	if root_gen:
		root_gen.genetics_changed.connect(_on_genetics_changed)

func _on_genetics_changed(cache: Dictionary) -> void:
	cached_multipliers = cache.duplicate()

	# 重算上限
	var base_hp = cache.get("base_max_hp_bonus", 100)
	var hp_mult = cache.get("defense_mult", 1.0)
	max_health = int(base_hp * hp_mult)

	var base_mana = cache.get("base_max_mana_bonus", 50)
	# 如果有神识加成，可以去调 SpiritMindAttr，但为了单向数据流，我们也可以在初始化时由上层注入
	var spirit = get_parent().get_node_or_null("SpiritMindAttr")
	var ds = spirit.divine_sense if spirit else 10
	max_mana = int(base_mana + ds * 15)

	# 限值校验
	current_health = clamp(current_health, 0, max_health)
	current_mana = clamp(current_mana, 0, max_mana)

	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

# --- 兼容旧 Stats 的战斗接口 ---
func heal(amount: int) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)

func damage(amount: int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

func restore_mana(amount: int) -> void:
	current_mana = clamp(current_mana + amount, 0, max_mana)
	mana_changed.emit(current_mana, max_mana)

func consume_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

# 提供倍率查询给战斗组件
func get_multiplier(key: String, default_val: float = 1.0) -> float:
	return cached_multipliers.get(key, default_val)
