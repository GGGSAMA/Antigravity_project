extends Node
class_name SocialData

const CharacterData = preload("res://core/simulation/character_data.gd")

var fame: int = 0
var karma: int = 0

func sync_from_resource(data: CharacterData) -> void:
	fame = data.fame
	karma = data.karma

# SocialData 暂时不需要为战斗提供乘区缓存，如果有需要可以加
func build_cache(data: CharacterData) -> Dictionary:
	var cache = {}
	
	# 业力可能影响雷系伤害承受倍率？预留
	cache["lightning_vuln"] = 1.0 + (max(0, -karma) / 1000.0)
	
	return cache
