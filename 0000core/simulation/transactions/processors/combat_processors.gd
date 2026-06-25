class_name CombatProcessors
extends RefCounted

# ==============================================================================
# 【战斗/伤害结算处理器集合】
# 实现宗门大比、野外夺宝等场景下的伤害与动机推演结算。
# ==============================================================================

# ------------------------------------------------------------------------------
# 伤害结算与动机评估器 (Combat Resolution Processor)
# ------------------------------------------------------------------------------
class ResolutionProcessor extends StepProcessor:
	func process(ticket: TransactionTicket, time_delta: float) -> Result:
		# 此处模拟战斗结束后的瞬间
		var attacker_id = ticket.initiator_id
		var victim_id = ticket.context.get("victim_id", "")
		var damage_severity = ticket.context.get("damage_severity", 0.0) # 0-100的严重程度

		var attacker = _get_npc(attacker_id)
		var victim = _get_npc(victim_id)

		if not attacker or not victim:
			return Result.REJECT

		# 如果受到的伤害达到了“致残/极度恶劣”的阈值
		if damage_severity >= 80.0:
			# 核心机制：呼叫社交大脑，评估肇事者平时的真实态度
			var eval_result = SocialEvaluator.calculate_attitude(attacker, victim)
			var rg = Engine.get_main_loop().root.get_node("RelationshipGraph")
			var eb = Engine.get_main_loop().root.get_node("EventBus")

			if eval_result.final_stance <= RelationshipGraph.Stance.DISDAIN:
				# 恶意伤人/借机杀人
				if rg: rg.add_relation(victim_id, attacker_id, "blood_feud", false)
				if eb: eb.emit_signal("narrative_event", "vowed_revenge", victim, attacker, eval_result)

			elif eval_result.final_stance >= RelationshipGraph.Stance.FRIENDLY:
				# 痛失所爱/严重误伤
				if rg: rg.add_relation(attacker_id, victim_id, "extreme_guilt", false)
				if eb: eb.emit_signal("narrative_event", "tragic_accident", attacker, victim, eval_result)

			else:
				# 普通路人结仇
				if rg: rg.add_relation(victim_id, attacker_id, "grudge", false)
				if eb: eb.emit_signal("narrative_event", "grudge_formed", victim, attacker, eval_result)

		return Result.PASS
