extends Node

const ChronicleTemplates = preload("res://0000core/simulation/events/chronicle_templates.gd")

# ==============================================================================
# 【履历与墓志铭生成中枢 (Chronicle Manager)】
# 统一管理角色的生平履历格式化，以及死亡后的长文传记拼装。
# ==============================================================================

# ------------------------------------------------------------------------------
# 接口一：获取流水账履历（供 F4 面板直接调用）
# ------------------------------------------------------------------------------
func get_detailed_history(npc: CharacterData) -> String:
	if not npc.get("history_trajectory"):
		return "此人一生平淡，未留下任何事迹。"

	var history = npc.history_trajectory
	if history.size() == 0:
		return "此人一生平淡，未留下任何事迹。"

	var result = ""
	for entry in history:
		result += "[%d岁] %s\n" % [entry.get("age", 0), entry.get("text", "")]
	return result

# ------------------------------------------------------------------------------
# 接口二：生成活侠传风格的“结语/墓志铭” (供死亡/通关画面调用)
# ------------------------------------------------------------------------------
func generate_epitaph(npc: CharacterData, death_cause: String = "lifespan_limit") -> String:
	var epitaph = "【" + npc.npc_name + " 之传记】\n\n"

	# 1. 拼接前言 (Intro)
	epitaph += _generate_intro(npc) + "\n\n"

	# 2. 拼接高光正文 (Body)
	epitaph += _generate_body(npc) + "\n\n"

	# 3. 拼接结语 (Outro)
	epitaph += _generate_outro(npc, death_cause)

	return epitaph

func _generate_intro(npc: CharacterData) -> String:
	var realm = 1
	if npc.get("cultivation_comp"):
		realm = npc.cultivation_comp.cultivation_realm

	var is_high_realm = realm >= 3 # 金丹及以上算大能
	var is_evil = npc.karma < -100 or npc.trait_morality < 30 # 恶人判定

	var pool_key = ""
	if is_high_realm and is_evil: pool_key = "realm_high_evil"
	elif is_high_realm and not is_evil: pool_key = "realm_high_good"
	elif not is_high_realm and is_evil: pool_key = "realm_low_evil"
	else: pool_key = "realm_low_good"

	var pool = ChronicleTemplates.INTRO_TEMPLATES[pool_key]
	return pool[randi() % pool.size()]

func _generate_body(npc: CharacterData) -> String:
	if not npc.get("history_trajectory") or npc.history_trajectory.size() == 0:
		return "你的一生平淡如水，日复一日地在宗门打坐，没有卷入任何惊天动地的因果。"

	# 抽取 level >= 2 的高光事件
	var highlights = []
	for entry in npc.history_trajectory:
		if entry.get("level", 1) >= 2:
			highlights.append(entry)

	if highlights.size() == 0:
		return "岁月流转，你谨慎地避开了修仙界的所有凶险，但也错失了逆天改命的机缘。"

	# 拼装（最多取最具代表性的前3条或随机3条，这里做简单的全量拼接展示，实战可截断）
	var body_text = ""
	var count = 0
	for h in highlights:
		if count >= 3: break # 只选3段高光
		body_text += "%d岁那年，%s\n" % [h.get("age", 0), h.get("text", "")]
		count += 1

	return body_text.strip_edges()

func _generate_outro(npc: CharacterData, death_cause: String) -> String:
	var pool_key = "alone_old_age"

	if death_cause == "killed":
		pool_key = "killed_in_action"
	elif death_cause == "killed_by_monster":
		pool_key = "killed_by_monster"
	else:
		# 寿终正寝，查看看有没有道侣
		var rg = Engine.get_main_loop().root.get_node_or_null("RelationshipGraph")
		if rg:
			# 这里简化判定，如果他的社会关系网里有 FRIENDLY 以上的，就算有挚友送终
			# 实战中可以去查 edges 里有没有 dao_companion
			pool_key = "has_partner_old_age" # 假设有

	var pool = ChronicleTemplates.OUTRO_TEMPLATES[pool_key]
	return pool[randi() % pool.size()]
