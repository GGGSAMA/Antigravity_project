extends Node
class_name SocialData

# ==============================================================================
# 【社会与性格数据 (Social Data)】
# 记录角色的名声、业力以及核心性格底色，为社交推演提供数据源。
# ==============================================================================

const CharacterData = preload("res://0000core/simulation/character_data.gd")

@export_group("Reputation & Karma")
@export var fame: int = 0
@export var karma: int = 0

@export_group("Personality Base (性格底色)")
@export_range(-1.0, 1.0) var alignment: float = 0.0 # 善恶度：-1.0 极恶, 1.0 至善
@export_range(0.0, 1.0) var arrogance: float = 0.5  # 傲慢度：越高越看不起资质差的人
@export_range(0.0, 360.0) var affinity_base: float = 0.0 # 相性原色 (类似三国志的相性轮盘)

func sync_from_resource(data: CharacterData) -> void:
	fame = data.fame
	karma = data.karma

# SocialData 暂时不需要为战斗提供乘区缓存，如果有需要可以加
func build_cache(data: CharacterData) -> Dictionary:
	var cache = {}
	
	# 业力可能影响雷系伤害承受倍率？预留
	cache["lightning_vuln"] = 1.0 + (max(0, -karma) / 1000.0)
	
	return cache
