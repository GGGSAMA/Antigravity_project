extends SceneTree

const CharacterData = preload("res://0000core/simulation/character_data.gd")
const CultivationComponent = preload("res://0000core/simulation/components/cultivation_component.gd")

func _init():
	print("\n=== 启动狩猎流水线独立测试 ===")
	
	# 环境准备
	var tm = TransactionManager.new()
	tm.name = "TransactionManager"
	root.add_child(tm)
	
	var dm = DeathManager.new()
	dm.name = "DeathManager"
	root.add_child(dm)
	
	var cm = ChronicleManager.new()
	cm.name = "ChronicleManager"
	root.add_child(cm)
	
	var sm = SocialManager.new()
	sm.name = "SocialManager"
	root.add_child(sm)
	
	# ----------------------------------------
	# 测试 1: 谨慎的高手去打猎 (稳赢碾压)
	# ----------------------------------------
	var npc1 = CharacterData.new()
	npc1.npc_id = "hunter_pro"
	npc1.npc_name = "稳健师兄"
	npc1.combat_power = 5000 # 极高战力
	npc1.trait_cautious = 90
	npc1.trait_ambition = 20
	var cult1 = CultivationComponent.new()
	cult1.cultivation_realm = 3 # 金丹
	npc1.add_child(cult1)
	npc1.cultivation_comp = cult1
	sm.npc_attributes[npc1.npc_id] = npc1
	
	# ----------------------------------------
	# 测试 2: 极度鲁莽的新手去打猎 (概率暴毙)
	# ----------------------------------------
	var npc2 = CharacterData.new()
	npc2.npc_id = "hunter_noob"
	npc2.npc_name = "莽夫师弟"
	npc2.combat_power = 10 # 极低战力
	npc2.stamina = 100
	npc2.trait_cautious = 10
	npc2.trait_ambition = 90
	var cult2 = CultivationComponent.new()
	cult2.cultivation_realm = 1 # 炼气
	npc2.add_child(cult2)
	npc2.cultivation_comp = cult2
	sm.npc_attributes[npc2.npc_id] = npc2
	
	print("\n[回合 1] 稳健师兄出手...")
	MacroActions._execute_hunt(npc1, 1.0)
	tm._process(1.0) # 驱动 TransactionManager 处理单据
	
	print("\n[回合 2] 莽夫师弟出手 (连续打猎几次直到暴毙)...")
	for i in range(5):
		if not npc2.is_alive: break
		print("  -> 第 %d 次进山" % (i+1))
		MacroActions._execute_hunt(npc2, 1.0)
		tm._process(1.0)
	
	if not npc2.is_alive:
		print("\n[讣告] 莽夫师弟已死，生成墓志铭：")
		print("------------------------------------------------")
		print(cm.generate_epitaph(npc2, "killed_by_monster"))
		print("------------------------------------------------")

	print("\n=== 测试完成 ===")
	quit()
