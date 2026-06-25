extends SceneTree

const CharacterData = preload("res://0000core/simulation/character_data.gd")
const SocialData = preload("res://00040components/stats/social_data.gd")
const CultivationComponent = preload("res://0000core/simulation/components/cultivation_component.gd")

func _init():
	print("\n=== 启动终生履历生成系统集成测试 ===")

	# 强行给 SceneTree 添加环境
	var cm = ChronicleManager.new()
	cm.name = "ChronicleManager"
	root.add_child(cm)

	var rg = RelationshipGraph.new()
	rg.name = "RelationshipGraph"
	root.add_child(rg)

	# 制造测试角色
	var player = CharacterData.new()
	player.npc_id = "player_1"
	player.npc_name = "张三"
	player.karma = -200 # 极恶

	var cult_p = CultivationComponent.new()
	cult_p.cultivation_realm = 4 # 元婴大能
	player.add_child(cult_p)
	player.cultivation_comp = cult_p

	# 伪造一生的履历
	player.history_trajectory = [
		{"age": 16, "text": "拜入天魔宗，成为外门弟子。", "level": 1},
		{"age": 18, "text": "在秘境中为夺一株血灵草，残杀同门三名。", "level": 2},
		{"age": 30, "text": "成功突破筑基期。", "level": 1},
		{"age": 45, "text": "【角色绝笔日记】“李四！今日断臂之仇，他日定叫你满门抄斩！”", "level": 3, "type": "BLOOD_FEUD"},
		{"age": 120, "text": "成功结丹，寿元大涨。", "level": 1},
		{"age": 200, "text": "血洗李四家族三十六口，炼制万魂幡。", "level": 3, "type": "REVENGE"},
		{"age": 350, "text": "突破元婴期，震动整个南荒修仙界。", "level": 2}
	]

	# 测试接口一：F4流水账
	print("\n[接口一：F4 面板流水账履历]")
	print("------------------------------------------------")
	print(cm.get_detailed_history(player))

	# 测试接口二：活侠传风格墓志铭
	print("\n[接口二：死亡结语 / 墓志铭]")
	print("------------------------------------------------")
	# 模拟大限将至，且孤身一人
	var epitaph = cm.generate_epitaph(player, "lifespan_limit")
	print(epitaph)
	print("------------------------------------------------")

	print("\n=== 测试完成 ===")
	quit()
