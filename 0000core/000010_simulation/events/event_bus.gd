extends Node

# ==============================================================================
# 【事件总线 (EventBus)】
# 负责在代码各处提供极简的接口：EventBus.emit_npc_event(npc, "breakthrough_success", {"realm": "筑基期"})
# ==============================================================================

signal npc_event_occurred(npc: CharacterData, event_id: String, ctx: Dictionary)
signal narrative_event(type: String, initiator: CharacterData, target: CharacterData, context: Variant)
signal level_changing
signal npc_died(npc_data, cause)
signal npc_status_changed(npc_id: String, tag: String, is_added: bool)

# UI 交互系统总线信号
signal request_open_ui(ui_name: String)
signal ui_state_changed(is_in_ui: bool)
signal show_notification(msg: String)
func _ready() -> void:
	npc_event_occurred.connect(_on_npc_event_occurred)

# 业务代码统一调用这个极简接口
func emit_npc_event(npc: CharacterData, event_id: String, context: Dictionary = {}) -> void:
	npc_event_occurred.emit(npc, event_id, context)

# 统一处理日志与入库
func _on_npc_event_occurred(npc: CharacterData, event_id: String, ctx: Dictionary) -> void:
	var event_data = EventRegistry.get_event_data(event_id)
	var level = event_data["level"]
	var template = event_data["template"]
	
	var type = event_data.get("type", "routine")
	
	# 解析模板里的占位符 (e.g. {item})
	var final_msg = template
	for key in ctx.keys():
		final_msg = final_msg.replace("{" + key + "}", str(ctx[key]))
		
	# 统一调用底层的 MacroActions 存储历史（或者可以直接在这里存）
	# 为了不产生循环依赖，我们直接在这里写存入逻辑，或者调用已有的接口
	_store_history(npc, final_msg, level, type)

func _store_history(npc: CharacterData, msg: String, level: int, type: String) -> void:
	# 写入个人日记（结构化）
	npc.history_trajectory.append({"age": npc.age, "text": msg, "level": level, "type": type})
	if npc.history_trajectory.size() > 50:
		npc.history_trajectory.pop_front()
	
	# 如果星级足够，触发天道播报
	var ms = get_node_or_null("/root/MacroSimulator")
	if ms and level >= ms.broadcast_level:
		if ms.has_signal("macro_event_logged"):
			var entry = "[骨龄%d岁] %s" % [npc.age, msg]
			ms.macro_event_logged.emit("【%s】 %s" % [npc.npc_name, entry])
