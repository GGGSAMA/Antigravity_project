extends Node
class_name RootGenAttr

signal genetics_changed(cache: Dictionary)

const CharacterData = preload("res://core/simulation/character_data.gd")
var spiritual_roots: Dictionary = {"metal": 20, "wood": 20, "water": 20, "fire": 20, "earth": 20}
var cultivation_realm: int = 1
var aptitude: int = 50

# 纯静态、极其低频地更新
func sync_from_resource(data: CharacterData) -> void:
	spiritual_roots = data.spiritual_roots.duplicate()
	cultivation_realm = data.cultivation_comp.cultivation_realm
	aptitude = data.aptitude
	_recalculate_and_broadcast()

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
