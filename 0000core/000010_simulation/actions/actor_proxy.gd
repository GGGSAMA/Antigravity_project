extends RefCounted
class_name ActorProxy

# ==============================================================================
# ActorProxy (门面模式：代理玩家实体与NPC数据的差异)
# ==============================================================================
# 无论是挂载了无数 Node 的玩家 3D 实体，还是仅仅是一个 Resource 的 NPC CharacterData，
# 统一包装为此接口，让 ChronosAction 能用同一套逻辑结算打坐、劫道、炼丹等行为。

var _source: Variant
var is_player: bool = false
var id: String = ""
var current_context: Dictionary = {}

func _init(source: Variant, context: Dictionary = {}):
	_source = source
	current_context = context
	if source is Node:
		is_player = true
		id = "player"
	else:
		is_player = false
		if source and "npc_id" in source:
			id = source.npc_id

func get_name() -> String:
	if is_player:
		return "玩家"
	elif _source and "npc_name" in _source:
		return _source.npc_name
	return "未知"

# ------------------ 通用属性读写 ------------------
func get_stat(stat_name: String) -> Variant:
	# 特殊处理 CultivationComponent 的变量
	if stat_name == "is_bottlenecked" or stat_name == "current_qi" or stat_name == "aptitude":
		if is_player:
			var cult = _source.get_node_or_null("ActorDataTemplate/RootGenAttr")
			if cult and stat_name in cult:
				return cult.get(stat_name)
		else:
			if _source and "cultivation_comp" in _source and _source.cultivation_comp and stat_name in _source.cultivation_comp:
				return _source.cultivation_comp.get(stat_name)
		return null

	if is_player:
		var stats = _source.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		if stats and stat_name in stats:
			return stats.get(stat_name)
	else:
		if _source and stat_name in _source:
			return _source.get(stat_name)
	return null

func set_stat(stat_name: String, value: Variant) -> void:
	if is_player:
		var stats = _source.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		if stats and stat_name in stats:
			stats.set(stat_name, value)
	else:
		if _source and stat_name in _source:
			_source.set(stat_name, value)

func add_stat(stat_name: String, amount: float) -> void:
	if stat_name == "current_qi":
		if is_player:
			var cult = _source.get_node_or_null("ActorDataTemplate/RootGenAttr")
			if cult and cult.has_method("add_qi"):
				cult.add_qi(amount)
		else:
			if _source and "cultivation_comp" in _source and _source.cultivation_comp:
				_source.cultivation_comp.add_qi(amount)
		return

	var current = get_stat(stat_name)
	if current != null:
		set_stat(stat_name, current + amount)

# ------------------ 行为特有方法 ------------------
func add_item(item_id: String, amount: int) -> void:
	# TODO: 接入真实的库存系统
	print("[ActorProxy] %s 获得了物品 %s x%d" % [get_name(), item_id, amount])

func remove_item(item_id: String, amount: int) -> bool:
	# TODO: 接入真实的库存系统
	return true

func die(reason: String = "") -> void:
	if not is_player:
		if _source and "is_alive" in _source:
			_source.is_alive = false
		print("[ActorProxy] NPC %s 陨落了。原因: %s" % [get_name(), reason])
	else:
		print("[ActorProxy] 玩家死亡。")

# ------------------ 履历与突破 ------------------
func add_history_log(msg: String, level: int = 2) -> void:
	if is_player:
		# Player doesn't use CharacterData history trajectory yet
		pass
	else:
		if _source and "history_trajectory" in _source:
			var age = _source.age if "age" in _source else 0
			_source.history_trajectory.append({"age": age, "text": msg, "level": level, "type": "routine"})
			
			# 同步触发天道播报
			var ms = Engine.get_main_loop().root.get_node_or_null("MacroSimulator")
			if ms and level >= ms.broadcast_level:
				if ms.has_signal("macro_event_logged"):
					var entry = "[骨龄%d岁] %s" % [age, msg]
					var npc_name = _source.npc_name if "npc_name" in _source else "未知"
					ms.macro_event_logged.emit("【%s】 %s" % [npc_name, entry])

func attempt_breakthrough() -> bool:
	if is_player:
		var cult = _source.get_node_or_null("ActorDataTemplate/RootGenAttr")
		if cult and cult.has_method("attempt_breakthrough"):
			return cult.attempt_breakthrough(true)
	else:
		if _source and "cultivation_comp" in _source and _source.cultivation_comp:
			return _source.cultivation_comp.attempt_breakthrough(false)
	return false

# ------------------ 泛用标签系统 (组合架构核心) ------------------
func has_tag(tag: String) -> bool:
	if is_player:
		var stats = _source.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		if stats and "tags" in stats:
			return stats.tags.has(tag)
	else:
		if _source and "tags" in _source:
			return _source.tags.has(tag)
	return false

func add_tag(tag: String) -> void:
	if is_player:
		var stats = _source.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		if stats and "tags" in stats:
			if not stats.tags.has(tag): stats.tags.append(tag)
	else:
		if _source and "tags" in _source:
			if not _source.tags.has(tag): _source.tags.append(tag)

func remove_tag(tag: String) -> void:
	if is_player:
		var stats = _source.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		if stats and "tags" in stats:
			stats.tags.erase(tag)
	else:
		if _source and "tags" in _source:
			_source.tags.erase(tag)
