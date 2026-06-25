class_name HuntProcessors
extends RefCounted

# ==============================================================================
# 【狩猎/猎魔 事务处理器集合】
# ==============================================================================

# ------------------------------------------------------------------------------
# 第一层：索敌层 (TargetSelectionProcessor)
# ------------------------------------------------------------------------------
class TargetSelectionProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc = _get_npc(ticket.initiator_id)
		if not npc: return Result.REJECT

		# 读取自身实力
		var realm = 1
		if npc.get("cultivation_comp"):
			realm = npc.cultivation_comp.cultivation_realm

		# 基于性格决定去打什么级别的怪 (越鲁莽越容易越级挑战)
		var is_reckless = npc.trait_cautious < 30 and npc.trait_ambition > 70
		var target_tier = realm
		if is_reckless and randf() < 0.3:
			target_tier += 1 # 越级挑战！

		# 根据等阶生成虚拟妖兽数据写入上下文
		var monster_names = {
			1: ["疾风狼", "黑角斑蝥", "毒沼蛙"],
			2: ["嗜血狂狮", "铁甲犀牛", "鬼面蛛"],
			3: ["赤炎金猊", "幽冥雷蛟", "裂天鹰"],
			4: ["九幽冥雀", "吞天蟒", "虚空行者"]
		}

		var pool = monster_names.get(target_tier, ["未知大妖"])
		var target_name = pool[randi() % pool.size()]
		var target_power = (target_tier * 100) + randi_range(-20, 50)

		ticket.context["monster_name"] = target_name
		ticket.context["monster_tier"] = target_tier
		ticket.context["monster_power"] = target_power

		return Result.PASS

# ------------------------------------------------------------------------------
# 第二层：战斗演算层 (CombatSimulationProcessor)
# ------------------------------------------------------------------------------
class CombatSimulationProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc = _get_npc(ticket.initiator_id)
		if not npc: return Result.REJECT

		var npc_power = npc.combat_power
		var target_power = ticket.context.get("monster_power", 50)

		# 加入随机骰子 (1d20 影响 10% 的战力浮动)
		var npc_roll = randf_range(0.9, 1.1)
		var monster_roll = randf_range(0.9, 1.1)

		var final_npc_score = npc_power * npc_roll
		var final_monster_score = target_power * monster_roll

		var combat_result = "DRAW"
		var power_ratio = final_npc_score / max(1.0, final_monster_score)

		if power_ratio > 1.5:
			combat_result = "CRITICAL_WIN" # 碾压
		elif power_ratio > 1.0:
			combat_result = "WIN_WITH_INJURY" # 惨胜
		elif power_ratio > 0.6:
			combat_result = "FLEE" # 败逃
		else:
			combat_result = "CRITICAL_LOSS" # 险遭不测 / 死亡

		ticket.context["combat_result"] = combat_result
		return Result.PASS

# ------------------------------------------------------------------------------
# 第三层：伤势与战利品结算层 (SettlementProcessor)
# ------------------------------------------------------------------------------
class SettlementProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		var npc = _get_npc(ticket.initiator_id)
		if not npc: return Result.REJECT

		var result = ticket.context.get("combat_result", "DRAW")
		var m_name = ticket.context.get("monster_name", "妖兽")
		var m_tier = ticket.context.get("monster_tier", 1)

		var msg = ""

		match result:
			"CRITICAL_WIN":
				npc.need_resource -= 20.0
				msg = "在山脉深处遭遇【%d阶%s】，三招之内将其斩杀，收获大量材料！" % [m_tier, m_name]

			"WIN_WITH_INJURY":
				npc.need_resource -= 15.0
				npc.stamina -= 30
				npc.need_healing += 50.0
				msg = "与【%d阶%s】激斗一天一夜，拼着轻伤将其斩杀，赚取了微薄的灵石。" % [m_tier, m_name]

			"FLEE":
				npc.stamina -= 60
				npc.need_healing += 80.0
				msg = "试图猎杀【%d阶%s】却遭反击，重伤吐血，使用血遁秘术才勉强逃生！" % [m_tier, m_name]

			"CRITICAL_LOSS":
				npc.stamina -= 90
				npc.need_healing += 100.0

				# 触发极端伤害逻辑！借助现有的 CombatProcessors 框架，其实只要有重伤就可以写日记。
				# 但由于这里是野外打怪，没有具体的 npc 凶手，所以我们直接写日记。
				var diary = "【绝笔残卷】“不！我怎么会死在这区区【%d阶%s】的爪下！我还没走到那长生之巅......”" % [m_tier, m_name]
				if npc.get("history_trajectory") != null:
					npc.history_trajectory.append({"age": npc.age, "text": diary, "level": 3, "type": "KILLED_BY_MONSTER"})
				msg = "在禁地遭遇【%d阶%s】，因战力悬殊，惨遭撕裂重创，命悬一线！" % [m_tier, m_name]

				# 可选：直接判定死亡
				if npc.stamina <= 0:
					var death_mgr = Engine.get_main_loop().root.get_node_or_null("DeathManager")
					if death_mgr:
						death_mgr.process_death(npc, "killed_by_monster")
					return Result.PASS

		# 写入普通日志
		if npc.get("history_trajectory") != null and result != "CRITICAL_LOSS":
			npc.history_trajectory.append({"age": npc.age, "text": msg, "level": 1})

		print("[HuntingPipeline] %s: %s" % [npc.npc_name, msg])
		return Result.PASS
