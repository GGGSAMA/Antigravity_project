class_name DeathManager
extends RefCounted

static func process_death(data: CharacterData, cause: String, killer: Node = null) -> void:
	if not data or not data.is_alive: return

	data.is_alive = false

	# 元婴及以上保留“元神”
	var realm = 0
	if data.cultivation_comp:
		realm = data.cultivation_comp.cultivation_realm

	if realm >= 4:
		data.current_action = "soul_fleeing"
		_broadcast_event("【天地变色】[%s] %s 肉身陨落，元神出窍远遁而去！" % [data.cultivation_comp.get_realm_name(), data.npc_name])
	else:
		data.current_action = "dead"

	if cause == "old_age":
		_handle_macro_death(data, realm)
	elif cause == "combat":
		_handle_micro_death(data, realm, killer)

	# 通知3D皮囊（如果存在）执行死亡动画和销毁
	if Engine.get_main_loop().root.has_node("EventBus"):
		Engine.get_main_loop().root.get_node("EventBus").npc_died.emit(data, cause)

static func _handle_macro_death(data: CharacterData, realm: int) -> void:
	var realm_name = data.cultivation_comp.get_realm_name() if data.cultivation_comp else "凡人"
	_broadcast_event("【陨落】[%s] %s 寿元尽矣，坐化于天地之间。" % [realm_name, data.npc_name])

	# 如果是高阶修士老死，生成洞府 POI 逻辑（这里预留接口给大地图系统）
	if realm >= 3:
		_broadcast_event("【机缘】传闻 [%s] 坐化之处（%s），隐隐有异宝出世..." % [data.npc_name, data.current_location])

static func _handle_micro_death(data: CharacterData, realm: int, killer: Node) -> void:
	var killer_name = "未知大能"
	if killer and killer.has_method("get_name"):
		killer_name = killer.name
	elif killer and "data" in killer and killer.data:
		killer_name = killer.data.npc_name

	_broadcast_event("【血光之灾】%s 技不如人，惨遭 %s 击杀！" % [data.npc_name, killer_name])

static func _broadcast_event(msg: String) -> void:
	print("[DeathManager] ", msg)
	var ms = Engine.get_main_loop().root.get_node_or_null("MacroSimulator")
	if ms and ms.has_signal("macro_event_logged"):
		ms.macro_event_logged.emit(msg)
