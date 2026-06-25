extends ChronosAction

func _init() -> void:
	action_id = "comprehend"
	action_name = "参悟功法"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return true 

func evaluate_utility(actor: ActorProxy) -> float:
	# NPC AI 目前可能不会主动参悟特定功法，主要由玩家触发
	return 10.0

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var days = hours_passed / 24.0
	var spell_id = actor.current_context.get("spell_id", "")
	
	if spell_id == "":
		actor.add_history_log("本想参悟功法，却心生杂念，一无所获。", 0)
		return

	# 获取基础属性，悟性影响参悟速度
	var comprehension = actor.get_stat("comprehension")
	if comprehension == null: comprehension = 10

	# 每天获得的基础功法经验
	var base_xp_regen = 50.0
	var xp_amount = int(base_xp_regen * days * (1.0 + float(comprehension) * 0.05))

	if actor.is_player:
		var parent = actor._source
		var spells_comp = parent.get_node_or_null("Spells")
		if spells_comp and spells_comp.has_method("add_spell_xp"):
			spells_comp.add_spell_xp(spell_id, xp_amount)
			var SpellDatabase = preload("res://0000core/data/spell_database.gd")
			var spell_data = SpellDatabase.get_spell(spell_id)
			var msg = "闭关参悟【%s】 %.1f 天，功法经验增加了 %d 点。" % [spell_data.name if spell_data else spell_id, days, xp_amount]
			log_event(actor, msg)
	else:
		# NPC的功法系统如果以后实现，可以在这里扩展
		var msg = "闭关参悟功法 %.1f 天，似乎有所心得。" % days
		if days >= 180:
			log_event(actor, msg)

