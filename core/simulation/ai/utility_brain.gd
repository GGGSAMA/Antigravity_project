extends Node
class_name UtilityBrain

# ==============================================================================
# 【功利大脑引擎 (UtilityBrain) - 需求与目标驱动版】
# 职责：
# 核心决策模块。
# 遵循架构链条：Goal加权 -> 计算最高 Need -> 结合 Trait 映射到具体 Action
#
# 架构规范：
# - 返回结构：{"name": "动作名", "need": "对应的需求名"}
# - 纯计算模块，绝不直接修改 NPC 状态。
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 寻找当前最高需求 (Goal 会影响 Need 的基础权重)
# ------------------------------------------------------------------------------
static func get_highest_need(npc: CharacterData) -> Dictionary:
	var needs = {
		"cultivation": npc.need_cultivation,
		"lifespan": npc.need_lifespan,
		"healing": npc.need_healing,
		"resource": npc.need_resource,
		"status": npc.need_status
	}
	
	# Goal 加权
	match npc.life_goal:
		"ASCEND":
			needs["cultivation"] += 20.0
		"REVENGE":
			needs["resource"] += 30.0
		"BUILD_SECT":
			needs["status"] += 20.0
			needs["resource"] += 10.0
		"CONQUER":
			needs["status"] += 30.0
			
	var max_need_name = "cultivation"
	var max_val = -999.0
	for k in needs.keys():
		if needs[k] > max_val:
			max_val = needs[k]
			max_need_name = k
			
	return {"name": max_need_name, "value": max_val}

# ------------------------------------------------------------------------------
# 2. 将最高需求转化为具体动作 (受性格影响)
# ------------------------------------------------------------------------------
static func determine_action(npc: CharacterData, top_need: Dictionary) -> Dictionary:
	var need_name = top_need.name
	var action_name = "无所事事"
	
	match need_name:
		"healing":
			action_name = "疗伤"
		"lifespan":
			action_name = "寻找延寿丹"
		"cultivation":
			# 性格随性（野心低）的 NPC，虽然也会修炼，但有一定概率去闲逛
			if npc.trait_ambition < 40 and randf() < 0.3:
				action_name = "云游闲逛"
			else:
				action_name = "闭关修炼"
		"status":
			if npc.trait_sociability > 50:
				action_name = "社交结网"
			else:
				action_name = "闭关修炼" # 宅男只相信实力等于地位
		"resource":
			if npc.trait_greed > 70 and npc.trait_morality < 30:
				action_name = "杀人越货"
			elif npc.trait_cautious > 60:
				action_name = "采集灵草"
			else:
				action_name = "坊市交易"
				
	return {"name": action_name, "need": need_name}

# ------------------------------------------------------------------------------
# 暴露给外部的旧接口，重定向到新的两步流程
# ------------------------------------------------------------------------------
static func evaluate_best_action(npc: CharacterData, karma_data: KarmaData = null) -> Dictionary:
	var top_need = get_highest_need(npc)
	return determine_action(npc, top_need)
