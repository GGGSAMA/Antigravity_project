class_name MacroActions
extends RefCounted

# 定义各个行为的评价函数和执行函数。分数越高越倾向于执行。

static func evaluate_cultivate(npc: NPCData) -> float:
	# 核心需求是修为 (cultivation)，如果数值低，则强烈渴望修炼
	var base_score = (100.0 - npc.needs.get("cultivation", 100.0)) * 1.5
	var weight = npc.personality_weights.get("cultivation_weight", 1.0)
	return base_score * weight

static func execute_cultivate(npc: NPCData) -> String:
	var old_val = npc.needs.get("cultivation", 0.0)
	var new_val = clamp(old_val + 30.0, 0.0, 100.0)
	npc.needs["cultivation"] = new_val
	return "[color=green]%s[/color] 闭关苦修 [color=cyan](修为 +%.1f, 当前: %.1f/100)[/color]" % [npc.npc_name, new_val - old_val, new_val]

static func evaluate_hunt(npc: NPCData) -> float:
	# 为了财富或安全
	var wealth_need = 100.0 - npc.needs.get("wealth", 100.0)
	var safety_need = 100.0 - npc.needs.get("safety", 100.0)
	var base_score = wealth_need * 1.0 + safety_need * 0.5
	var weight = npc.personality_weights.get("hunt_weight", 1.0)
	return base_score * weight

static func execute_hunt(npc: NPCData) -> String:
	var old_w = npc.needs.get("wealth", 0.0)
	var old_s = npc.needs.get("safety", 0.0)
	var new_w = clamp(old_w + 35.0, 0.0, 100.0)
	var new_s = clamp(old_s - 15.0, 0.0, 100.0)
	npc.needs["wealth"] = new_w
	npc.needs["safety"] = new_s
	return "[color=red]%s[/color] 外出夺宝杀人 [color=yellow](财富 +%.1f -> %.1f)[/color] [color=gray](安全 -%.1f -> %.1f)[/color]" % [npc.npc_name, new_w - old_w, new_w, old_s - new_s, new_s]

static func evaluate_heal(npc: NPCData) -> float:
	var safety_need = 100.0 - npc.needs.get("safety", 100.0)
	var base_score = safety_need * 2.0
	var weight = npc.personality_weights.get("heal_weight", 1.0)
	return base_score * weight

static func execute_heal(npc: NPCData) -> String:
	var old_s = npc.needs.get("safety", 0.0)
	var new_s = clamp(old_s + 40.0, 0.0, 100.0)
	npc.needs["safety"] = new_s
	return "[color=orange]%s[/color] 正在洞府疗伤 [color=green](安全 +%.1f, 当前: %.1f/100)[/color]" % [npc.npc_name, new_s - old_s, new_s]

static func evaluate_social(npc: NPCData) -> float:
	var social_need = 100.0 - npc.needs.get("social", 100.0)
	var base_score = social_need * 1.2
	var weight = npc.personality_weights.get("social_weight", 1.0)
	return base_score * weight

static func execute_social(npc: NPCData) -> String:
	var old_val = npc.needs.get("social", 0.0)
	var new_val = clamp(old_val + 30.0, 0.0, 100.0)
	npc.needs["social"] = new_val
	return "[color=pink]%s[/color] 下山寻找机缘结交道友 [color=purple](执念 +%.1f, 当前: %.1f/100)[/color]" % [npc.npc_name, new_val - old_val, new_val]
