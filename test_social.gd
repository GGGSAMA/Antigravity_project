extends SceneTree

const CharacterData = preload("res://0000core/simulation/character_data.gd")
const SocialData = preload("res://00010entities/components/stats/social_data.gd")
const CultivationComponent = preload("res://0000core/simulation/components/cultivation_component.gd")

func _init():
	print("\n--- 启动社交推演单元测试 ---")
	
	# 强行给 SceneTree 添加 Autoload 环境
	var rg = RelationshipGraph.new()
	rg.name = "RelationshipGraph"
	root.add_child(rg)
	
	var se = SocialEvaluator.new()
	se.name = "SocialEvaluator"
	root.add_child(se)
	
	# 造数据：大佬 A (化神期，傲慢，邪修)
	var npc_a = CharacterData.new()
	npc_a.npc_id = "master_a"
	npc_a.npc_name = "傲天老祖"
	npc_a.aptitude = 90
	var cult_a = CultivationComponent.new()
	cult_a.name = "CultivationComponent"
	cult_a.cultivation_realm = 5 # 化神期
	npc_a.add_child(cult_a)
	var soc_a = SocialData.new()
	soc_a.name = "SocialData"
	soc_a.arrogance = 1.0 # 极度傲慢
	soc_a.alignment = -0.5 # 偏邪
	soc_a.affinity_base = 0.0
	npc_a.add_child(soc_a)
	
	# 造数据：菜鸡 B (炼气期，废灵根，暴富，相性冲突)
	var npc_b = CharacterData.new()
	npc_b.npc_id = "noob_b"
	npc_b.npc_name = "路人乙"
	npc_b.aptitude = 10 # 废灵根
	npc_b.money = 50000 # 带着巨款
	var cult_b = CultivationComponent.new()
	cult_b.name = "CultivationComponent"
	cult_b.cultivation_realm = 1 # 炼气期
	npc_b.add_child(cult_b)
	var soc_b = SocialData.new()
	soc_b.name = "SocialData"
	soc_b.affinity_base = 180.0 # 完全对立
	npc_b.add_child(soc_b)
	
	print("\n【测试用例 1：完全路人状态】")
	var res1 = se.calculate_attitude(npc_a, npc_b)
	print("结果：", res1.final_stance)
	for n in res1.notes:
		print(" - ", n)
		
	print("\n【测试用例 2：结为道侣（打脸时刻）】")
	rg.add_relation("master_a", "noob_b", "dao_companion", true)
	var res2 = se.calculate_attitude(npc_a, npc_b)
	print("结果：", res2.final_stance)
	for n in res2.notes:
		print(" - ", n)
		
	print("\n--- 测试完成 ---")
	quit()
