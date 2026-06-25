extends TimeNode

# ==============================================================================
# 【宏观结算引擎 (MacroSimulator) - 万物行为大一统版】
# ==============================================================================

enum LogLevel {
	TRACE = 0,
	INFO = 1,
	IMPORTANT = 2,
	GLOBAL = 3
}

@export var broadcast_level: int = LogLevel.IMPORTANT
signal macro_event_logged(msg: String)

func _ready() -> void:
	granularity = TimeGranularity.MONTH # NPC 宏观结算一般按月粒度
	priority = SettlePriority.SOCIETY   # 优先级为 SOCIETY
	super._ready()

	print("[MacroSimulator] 初始化后台大一统万物行为结算引擎... (已接入 ChronosScheduler)")

func _on_time_advanced(skipped_hours: float) -> void:
	print("[MacroSimulator] 收到跳跃指令，小时数：", skipped_hours)
	if skipped_hours <= 0.0: return

	var total_skipped_years = skipped_hours / (365.0 * 24.0)

	# 遍历所有NPC进行大一统推演
	if not Engine.get_main_loop().root.has_node("SocialManager") or not Engine.get_main_loop().root.has_node("ActionLibrary"):
		print("[MacroSimulator] 严重错误：SocialManager 或 ActionLibrary 未找到！")
		return

	print("[MacroSimulator] 开始遍历 ", Engine.get_main_loop().root.get_node("SocialManager").npc_attributes.size(), " 个 NPC...")

	var sm = Engine.get_main_loop().root.get_node("SocialManager")
	var action_lib = Engine.get_main_loop().root.get_node("ActionLibrary")

	for npc in sm.npc_attributes.values():
		var data = npc as CharacterData

		# 坍缩态或已死NPC不参与演化
		if not data or not data.is_alive or data.is_collapsed: continue

		# 1. 简易寿命积累 (整数年增加)
		if not data.has_meta("age_accum"): data.set_meta("age_accum", 0.0)
		var accum = data.get_meta("age_accum") + total_skipped_years
		if accum >= 1.0:
			var added_age = int(accum)
			data.age += added_age
			data.set_meta("age_accum", accum - added_age)
		else:
			data.set_meta("age_accum", accum)

		# 死劫判断
		if data.age >= data.max_lifespan:
			if Engine.get_main_loop().root.has_node("DeathManager"):
				Engine.get_main_loop().root.get_node("DeathManager").process_death(data, "old_age")
			else:
				data.is_alive = false
			continue

		# 寿元警告 (动态调整 Need)
		var remaining_life = data.max_lifespan - data.age
		if remaining_life < 10:
			data.need_lifespan += (10 - remaining_life) * 10.0

		# 驱动力自增引擎
		var growth_rate = 10.0
		data.need_cultivation = clamp(data.need_cultivation + growth_rate * total_skipped_years, 0.0, 100.0)

		# ==========================================
		# 2. 核心大一统行为解算管线 (Hooked with UtilityBrain)
		# ==========================================
		var proxy = ActorProxy.new(data)

		# 让 UtilityBrain 决定最佳行为 ID，实现底层硬解耦
		var chosen_action_result = UtilityBrain.evaluate_best_action(data)
		var best_action = action_lib.get_action(chosen_action_result.get("id", "meditate"))

		if best_action:
			# 状态发生变化时，通过 EventBus 抛出事件，杜绝硬编码耦合
			if data.current_action != best_action.action_id:
				if Engine.get_main_loop().root.has_node("EventBus"):
					Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(data, "action_changed", {"action_name": best_action.action_name})
				data.current_action = best_action.action_id

			best_action.settle_time_chunk(proxy, skipped_hours)
		else:
			var default_action = action_lib.get_action("meditate")
			if default_action:
				default_action.settle_time_chunk(proxy, skipped_hours)

	# ==========================================
	# 3. 大世界事务流转 (Transaction Pipeline)
	# ==========================================
	if Engine.get_main_loop().root.has_node("TransactionManager"):
		Engine.get_main_loop().root.get_node("TransactionManager").process_time_slice(total_skipped_years)
