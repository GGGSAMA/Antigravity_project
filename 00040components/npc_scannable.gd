extends ScannableComponent
class_name NPCScannableComponent

func get_scan_result(scanner_node: Node, scanner_divine_sense: int) -> Dictionary:
	var npc = get_parent()
	var npc_stats = npc.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
	var npc_divine_sense = 10
	if npc_stats and "divine_sense" in npc_stats and npc_stats.get("divine_sense") != null:
		npc_divine_sense = npc_stats.get("divine_sense")

	var diff = scanner_divine_sense - npc_divine_sense

	# 高位俯视 (完全看透)
	if diff >= 5:
		return {
			"name": scan_name,
			"icon": scan_icon,
			"color": scan_color
		}

	# 同阶试探 (部分信息，NPC 警戒)
	elif diff > -5 and diff < 5:
		if npc.has_method("on_being_spied"):
			npc.on_being_spied(scanner_node, false) # false 表示同阶
		return {
			"name": "实力相当的修士",
			"icon": "👤",
			"color": Color(0.8, 0.8, 0.2)
		}

	# 以下犯上 (看不透，且激怒高阶 NPC)
	else:
		if npc.has_method("on_being_spied"):
			npc.on_being_spied(scanner_node, true) # true 表示被低阶蝼蚁扫了，激怒
		return {
			"name": "深不可测的前辈 (？？？)",
			"icon": "💀",
			"color": Color(0.8, 0.2, 0.2)
		}
