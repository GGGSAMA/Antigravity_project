extends Node
class_name FiveElementRoot

const CharacterData = preload("res://0000core/simulation/character_data.gd")

var spiritual_roots: Dictionary = {}

func sync_from_resource(data: CharacterData) -> void:
	spiritual_roots = data.spiritual_roots.duplicate()

func build_cache(data: CharacterData) -> Dictionary:
	var cache = {}
	var elements = ["metal", "wood", "water", "fire", "earth"]
	
	for el in elements:
		var purity = spiritual_roots.get(el, 0)
		# 伤害倍率: 20纯度 -> 1.0x, 100纯度 -> 2.0x
		cache[el + "_dmg_mult"] = 1.0 + ((purity - 20) / 80.0)
		# CD 缩减: 20纯度 -> 0%, 100纯度 -> 50%
		cache[el + "_cd_reduction"] = clamp((purity - 20) / 160.0, 0.0, 0.5)
		# 耗蓝缩减: 20纯度 -> 0%, 100纯度 -> 50%
		cache[el + "_mana_reduction"] = clamp((purity - 20) / 160.0, 0.0, 0.5)
		
	# 特殊全局加成
	var wood_purity = spiritual_roots.get("wood", 0)
	cache["hp_regen_mult"] = 1.0 + (wood_purity / 50.0)
	
	var earth_purity = spiritual_roots.get("earth", 0)
	cache["defense_mult"] = 1.0 + (earth_purity / 50.0)
	
	return cache
