extends Node

# ==============================================================================
# 【社交态度演算中枢 (Social Evaluator)】
# 整体功能：
#   提供解耦的全局函数，用于计算 NPC A 对 目标 B 的瞬时态度 (Stance)。
# 状态设定：
#   无状态工厂，纯数学推演。
# 核心接口：
#   - calculate_attitude(initiator, target) -> Dictionary
# 架构分层：
#   1. Layer 0 (基础计算)：算境界碾压、资质鄙视、财富贪婪。
#   2. Layer 1 (图谱覆写)：向 RelationshipGraph 请求边界钳制 (Clamp)。
#   3. Layer 2 (性格变异)：基于 NPC 的独特性格在最终态产生变异。
# ==============================================================================

# 定义返回的结构
class AttitudeResult:
	var final_score: float
	var base_stance: RelationshipGraph.Stance
	var final_stance: RelationshipGraph.Stance
	var trigger_greed: bool = false # 是否因为对方带重宝而眼红
	var notes: Array = [] # 调试与溯源用

func _ready():
	pass

# 核心推演主函数
func calculate_attitude(initiator: CharacterData, target: CharacterData) -> AttitudeResult:
	var result = AttitudeResult.new()
	
	# ==========================================
	# Layer 0: 基础数据演算 (Base Calculation)
	# ==========================================
	var score: float = 0.0
	
	# 1. 境界差 (Realm Difference)
	var realm_diff = 0
	if initiator.has_node("CultivationComponent") and target.has_node("CultivationComponent"):
		var my_realm = initiator.get_node("CultivationComponent").cultivation_realm
		var tar_realm = target.get_node("CultivationComponent").cultivation_realm
		realm_diff = my_realm - tar_realm
		# 对方境界比我高，产生敬畏分（加分）；对方比我低，产生轻视分（扣分）
		score -= realm_diff * 10.0 
	
	# 2. 资质鄙视链 (Aptitude Chain)
	var target_aptitude = target.aptitude
	var my_arrogance = initiator.social_data.arrogance if initiator.has_node("SocialData") else 0.5
	if target_aptitude < 30: # 废灵根
		var penalty = 30.0 * my_arrogance
		score -= penalty
		result.notes.append("因对方资质低劣，扣除 " + str(penalty) + " 分")
		
	# 3. 基础相性夹角 (Affinity Base)
	if initiator.has_node("SocialData") and target.has_node("SocialData"):
		var my_aff = initiator.social_data.affinity_base
		var tar_aff = target.social_data.affinity_base
		var diff = abs(my_aff - tar_aff)
		if diff > 180: diff = 360 - diff
		# 夹角最大 180 度。夹角小加分，夹角大扣分。
		var aff_score = (90.0 - diff) * 0.5 # 范围 -45 到 +45
		score += aff_score
		result.notes.append("相性夹角差 " + str(diff) + " 度，得分变动 " + str(aff_score))
		
	# 4. 贪婪触发判定 (Greed Check)
	var my_alignment = initiator.social_data.alignment if initiator.has_node("SocialData") else 0.0
	var target_wealth = target.money # 未来可加装备估值
	# 邪修 (alignment < 0) 且 对方有钱，且我打得过对方 (realm_diff >= 0)
	if my_alignment < -0.2 and target_wealth > 10000 and realm_diff >= 0:
		result.trigger_greed = true
		score -= 50.0 # 见财起意，好感暴跌，准备杀人夺宝
		result.notes.append("见财起意，触发贪婪标志")
		
	result.final_score = score
	
	# 映射基础 Stance
	if score <= -50:
		result.base_stance = RelationshipGraph.Stance.HOSTILE_GREEDY
	elif score <= -20:
		result.base_stance = RelationshipGraph.Stance.DISDAIN
	elif score >= 80:
		result.base_stance = RelationshipGraph.Stance.FAWNING
	elif score >= 50:
		result.base_stance = RelationshipGraph.Stance.FRIENDLY
	else:
		result.base_stance = RelationshipGraph.Stance.NEUTRAL
		
	result.final_stance = result.base_stance
	
	# ==========================================
	# Layer 1: 关系网图谱覆写 (Relational Override Clamp)
	# ==========================================
	if Engine.get_main_loop().root.has_node("RelationshipGraph"):
		var rg = Engine.get_main_loop().root.get_node("RelationshipGraph")
		var clamp_data = rg.get_stance_clamp(initiator.npc_id, target.npc_id)
		
		if clamp_data["has_clamp"]:
			var min_s = clamp_data["min_stance"]
			var max_s = clamp_data["max_stance"]
			
			var old_stance = result.final_stance
			# 核心钳制逻辑：限制在 min 和 max 之间
			if result.final_stance < min_s:
				result.final_stance = min_s
			elif result.final_stance > max_s:
				result.final_stance = max_s
				
			if old_stance != result.final_stance:
				result.notes.append("触发关系网钳制：从 " + str(old_stance) + " 被覆写为 " + str(result.final_stance))
				
	# ==========================================
	# Layer 2: 极端性格变异 (Personality Mutation)
	# ==========================================
	# 例如：NPC 是个极度傲娇（假设有个 flag tsundere），即使内心是 FRIENDLY，表现出来也是 DISDAIN
	# 此处预留逻辑口
	
	return result
