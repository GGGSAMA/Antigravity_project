extends Node
class_name TraitFilter

# ==============================================================================
# 【性格过滤器 (TraitFilter)】
# 职责：
# 接收世界事件，经过性格扭曲后，转化为 NPC 内在驱动力（Need）的波动。
# 绝不允许直接根据事件指派动作。
# ==============================================================================

static func process_life_event(npc: CharacterData, event_type: String, data: Dictionary = {}) -> void:
	match event_type:
		"breakthrough_failed":
			_on_breakthrough_failed(npc, data)
		"injured":
			_on_injured(npc, data)
		"partner_killed":
			_on_partner_killed(npc, data)
		"robbed":
			_on_robbed(npc, data)
		_:
			pass

static func _on_breakthrough_failed(npc: CharacterData, data: Dictionary) -> void:
	# 突破失败：必定受伤，根据性格决定反应
	npc.stamina = max(10, npc.stamina - 50)
	
	if npc.trait_cautious > 70:
		# 极其谨慎：吓破胆了，疯狂想疗伤，不想修炼了
		npc.need_healing += 80.0
		npc.need_cultivation -= 30.0
	elif npc.trait_ambition > 70:
		# 极具野心：越挫越勇，迫切需要资源再次突破
		npc.need_healing += 30.0
		npc.need_cultivation += 50.0
		npc.need_resource += 40.0
	else:
		# 普通人
		npc.need_healing += 50.0

static func _on_injured(npc: CharacterData, data: Dictionary) -> void:
	var severity = data.get("severity", 30.0)
	npc.need_healing += severity
	
	if npc.trait_cautious > 60:
		npc.need_healing += severity * 0.5 # 更加怕死

static func _on_partner_killed(npc: CharacterData, data: Dictionary) -> void:
	# 道侣被杀：改变长期人生目标！
	if npc.trait_morality < 30 and npc.trait_greed > 70:
		# 薄情寡义：甚至可能觉得是好事
		pass
	else:
		# 正常/重情重义：升起复仇之火
		npc.life_goal = "REVENGE"
		npc.need_resource += 100.0 # 急需资源提升实力
		npc.need_cultivation += 50.0

static func _on_robbed(npc: CharacterData, data: Dictionary) -> void:
	# 被抢劫
	npc.need_resource += 50.0 # 钱没了，需要搞钱
	if npc.trait_cautious < 40 and npc.trait_ambition > 60:
		npc.life_goal = "REVENGE" # 记仇
