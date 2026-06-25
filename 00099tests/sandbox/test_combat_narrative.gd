extends SceneTree

const CharacterData = preload("res://0000core/simulation/character_data.gd")
const SocialData = preload("res://00040components/stats/social_data.gd")
const CultivationComponent = preload("res://0000core/simulation/components/cultivation_component.gd")

func _init():
	print("\n=== 启动战斗动机推演与叙事代入系统集成测试 ===")

	# 强行给 SceneTree 添加环境
	var eb = EventBus.new()
	eb.name = "EventBus"
	root.add_child(eb)

	var nd = NarrativeDirector.new()
	nd.name = "NarrativeDirector"
	root.add_child(nd)

	var rg = RelationshipGraph.new()
	rg.name = "RelationshipGraph"
	root.add_child(rg)

	var se = SocialEvaluator.new()
	se.name = "SocialEvaluator"
	root.add_child(se)

	# 模拟 TransactionTicket 上下文
	var ticket = TransactionTicket.new()

	# 制造受害者：玩家 (炼气期废柴)
	var player = CharacterData.new()
	player.npc_id = "player"
	player.npc_name = "韩跑跑"
	player.aptitude = 10
	var cult_p = CultivationComponent.new()
	cult_p.cultivation_realm = 1
	player.add_child(cult_p)
	var soc_p = SocialData.new()
	soc_p.affinity_base = 0
	player.add_child(soc_p)

	# ==========================================
	# 场景一：宗门大比中，被傲慢的内门反派打断经脉
	# ==========================================
	var villain = CharacterData.new()
	villain.npc_id = "villain"
	villain.npc_name = "傲天师兄"
	villain.aptitude = 90
	var cult_v = CultivationComponent.new()
	cult_v.cultivation_realm = 3
	villain.add_child(cult_v)
	var soc_v = SocialData.new()
	soc_v.arrogance = 1.0 # 极度傲慢，触发鄙视链
	villain.add_child(soc_v)

	# 临时注册到社会管理器模拟环境 (StepProcessor 需要用到 _get_npc)
	var sm = SocialManager.new()
	sm.name = "SocialManager"
	root.add_child(sm)
	sm.npc_attributes["player"] = player
	sm.npc_attributes["villain"] = villain

	print("\n--- 场景一：反派痛下杀手 ---")
	ticket.initiator_id = "villain"
	ticket.context["victim_id"] = "player"
	ticket.context["damage_severity"] = 90.0 # 致命致残伤

	var combat_proc = CombatProcessors.ResolutionProcessor.new()
	combat_proc.process(ticket, 1.0)

	# 验证标签
	var tags_v = rg.get_relation_tags("player", "villain")
	print("[图谱验证] 玩家对反派的标签: ", tags_v)

	# ==========================================
	# 场景二：宗门大比中，被友善的大师姐误伤打断经脉
	# ==========================================
	var sister = CharacterData.new()
	sister.npc_id = "sister"
	sister.npc_name = "温柔师姐"
	var cult_s = CultivationComponent.new()
	cult_s.cultivation_realm = 4
	sister.add_child(cult_s)
	var soc_s = SocialData.new()
	sister.add_child(soc_s)
	sm.npc_attributes["sister"] = sister

	# 先加上道侣关系
	rg.add_relation("sister", "player", "dao_companion", true)

	print("\n--- 场景二：师姐痛失所爱 ---")
	var ticket2 = TransactionTicket.new()
	ticket2.initiator_id = "sister"
	ticket2.context["victim_id"] = "player"
	ticket2.context["damage_severity"] = 90.0 # 致命致残伤

	combat_proc.process(ticket2, 1.0)

	# 验证标签
	var tags_s = rg.get_relation_tags("sister", "player")
	print("[图谱验证] 师姐对玩家的标签: ", tags_s)

	print("\n=== 测试完成 ===")
	quit()
