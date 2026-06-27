extends Node
class_name EncounterManager

# ==============================================================================
# 【独立机缘抽卡库 (Encounter Manager)】
# 职责：负责大世界推演中所有的“盲盒”和“随机事件”。
# 它将各种文字描述与真实的底层数据（背包、寿命、健康、金钱）绑定，
# 确保“机缘”不再是一句空话，而是真实的系统级改变。
# ==============================================================================

# 标准模版：云游机缘触发器
# 不再返回文字，而是直接抛出事件
static func trigger_wander_encounter(npc: CharacterData, time_spent: float) -> void:
	var roll = randf()

	# 【奇遇】10% 概率：坠崖得宝 / 古洞遗迹
	if roll < 0.10:
		var items = ["上古剑意残篇", "神秘丹药", "未知的法宝残片", "极品灵石"]
		var loot = items.pick_random()

		# 真实增加数据
		npc.inventory[loot] = npc.inventory.get(loot, 0) + 1
		npc.money += int(randf_range(1000, 5000))
		if npc.cultivation_comp:
			npc.cultivation_comp.add_qi(500.0 * (float(npc.aptitude) / 50.0))

		npc.need_cultivation = max(0.0, npc.need_cultivation - 30.0)
		if Engine.get_main_loop().root.has_node("EventBus"):
			Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(npc, "encounter_treasure", {"item": loot})

	# 【桃花/社交】20% 概率：结识新朋友
	elif roll < 0.30:
		npc.need_status = max(0.0, npc.need_status - 20.0)
		# TODO: 以后可以调用 SocialManager 真实建立人际关系
		if Engine.get_main_loop().root.has_node("EventBus"):
			Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(npc, "encounter_social")

	# 【厄运】10% 概率：遭遇危机
	elif roll < 0.40:
		var lost_money = min(npc.money, int(randf_range(100, 500)))
		npc.money -= lost_money
		npc.stamina = max(10, npc.stamina - 40) # 受伤掉体力
		npc.need_healing += 50.0 # 增加疗伤需求
		if Engine.get_main_loop().root.has_node("EventBus"):
			Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(npc, "encounter_trap", {"lost_money": lost_money})

	# 【平庸】60% 概率：一无所获
	else:
		npc.need_cultivation = max(0.0, npc.need_cultivation - 5.0) # 随性的人也能降低点疲劳
		if Engine.get_main_loop().root.has_node("EventBus"):
			Engine.get_main_loop().root.get_node("EventBus").emit_npc_event(npc, "wander_nothing", {"years": snapped(time_spent, 0.1)})
