extends Node
class_name RootGenAttr

signal genetics_changed(cache: Dictionary)

const CharacterData = preload("res://0000core/000010_simulation/entities/character_data.gd")
var spiritual_roots: Dictionary = {"metal": 20, "wood": 20, "water": 20, "fire": 20, "earth": 20}
var cultivation_realm: int = 1
var current_qi: float = 0.0
var max_qi: float = 1000.0
var is_bottlenecked: bool = false
var aptitude: int = 50

# 纯静态、极其低频地更新
func sync_from_resource(data: CharacterData) -> void:
	spiritual_roots = data.spiritual_roots.duplicate()
	cultivation_realm = data.cultivation_comp.cultivation_realm
	current_qi = data.cultivation_comp.current_qi
	max_qi = data.cultivation_comp.max_qi
	is_bottlenecked = data.cultivation_comp.is_bottlenecked
	aptitude = data.aptitude
	_recalculate_and_broadcast()

func add_qi(amount: float) -> void:
	if is_bottlenecked: return
	current_qi += amount
	if current_qi >= max_qi:
		current_qi = max_qi
		is_bottlenecked = true
	_recalculate_and_broadcast()

func attempt_breakthrough(is_player: bool = false) -> bool:
	if not is_bottlenecked: return false
	# 简单突破逻辑
	if randf() < 0.5 or is_player: # 玩家暂定 100% 成功
		cultivation_realm += 1
		current_qi = 0.0
		max_qi *= 2.0
		is_bottlenecked = false
		_recalculate_and_broadcast()
		if is_player:
			get_parent().get_parent().get_node("HUD/NotificationLabel").text = "突破成功！当前境界: " + str(cultivation_realm)
		return true
	return false


func _recalculate_and_broadcast() -> void:
	var cache = {}
	var elements = ["metal", "wood", "water", "fire", "earth"]
	for el in elements:
		var purity = spiritual_roots.get(el, 0)
		cache[el + "_dmg_mult"] = 1.0 + ((purity - 20) / 80.0)
		cache[el + "_cd_reduction"] = clamp((purity - 20) / 160.0, 0.0, 0.5)
		cache[el + "_mana_reduction"] = clamp((purity - 20) / 160.0, 0.0, 0.5)

	cache["hp_regen_mult"] = 1.0 + (spiritual_roots.get("wood", 0) / 50.0)
	cache["defense_mult"] = 1.0 + (spiritual_roots.get("earth", 0) / 50.0)

	cache["realm_power"] = float(cultivation_realm)
	cache["xp_gain_mult"] = float(aptitude) / 50.0

	# 这里只算基底，具体的血量上限基础由境界提供
	cache["base_max_hp_bonus"] = cultivation_realm * 100
	cache["base_max_mana_bonus"] = cultivation_realm * 50

	genetics_changed.emit(cache)
