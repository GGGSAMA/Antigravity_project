extends Node
class_name CultivateData

const CharacterData = preload("res://0000core/simulation/character_data.gd")

var cultivation_realm: int = 1
var cultivation_stage: int = 1
var aptitude: int = 50

func sync_from_resource(data: CharacterData) -> void:
	cultivation_realm = data.cultivation_comp.cultivation_realm if data.cultivation_comp else 1
	cultivation_stage = data.cultivation_comp.cultivation_stage if data.cultivation_comp else 1
	aptitude = data.aptitude

func build_cache(data: CharacterData) -> Dictionary:
	var cache = {}

	# 境界压制倍率（高一境界打低一境界有基础加成）
	cache["realm_power"] = float(cultivation_realm)

	# 资质带来的修炼速度倍率
	cache["xp_gain_mult"] = float(aptitude) / 50.0

	return cache
