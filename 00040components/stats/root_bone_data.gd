extends Node
class_name RootBoneData

signal multipliers_updated(new_cache: Dictionary)
signal stats_updated()

const CharacterData = preload("res://0000core/000010_simulation/entities/character_data.gd")

# 后台纯数据资源引用
var character_data: CharacterData

# 子组件引用
@onready var five_element = $FiveElementRoot
@onready var cultivate = $CultivateData
@onready var social = $SocialData

# 对外暴露的最终修正缓存池
var cached_multipliers: Dictionary = {}

func inject_data(data: CharacterData) -> void:
	character_data = data
	_sync_from_resource()

func _sync_from_resource() -> void:
	if not character_data: return

	if five_element and five_element.has_method("sync_from_resource"):
		five_element.sync_from_resource(character_data)
	if cultivate and cultivate.has_method("sync_from_resource"):
		cultivate.sync_from_resource(character_data)
	if social and social.has_method("sync_from_resource"):
		social.sync_from_resource(character_data)

	rebuild_cache()

func rebuild_cache() -> void:
	if not character_data: return

	cached_multipliers.clear()

	# 从五行灵根组件提取缓存
	if five_element and five_element.has_method("build_cache"):
		var element_cache = five_element.build_cache(character_data)
		for k in element_cache:
			cached_multipliers[k] = element_cache[k]

	# 从修为境界提取缓存
	if cultivate and cultivate.has_method("build_cache"):
		var cult_cache = cultivate.build_cache(character_data)
		for k in cult_cache:
			cached_multipliers[k] = cult_cache[k]

	emit_signal("multipliers_updated", cached_multipliers)
	emit_signal("stats_updated")

# 获取缓存的安全方法
func get_multiplier(key: String, default_val: float = 1.0) -> float:
	return cached_multipliers.get(key, default_val)
