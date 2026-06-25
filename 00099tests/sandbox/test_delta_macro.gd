extends Control

@onready var log_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	_append_log("初始化大千世界测试环境...")

	# 创建三个典型的 NPC
	var npc1 = CharacterData.new()
	npc1.npc_name = "王富贵 [极度谨慎]"
	npc1.trait_cautious = 90
	npc1.trait_ambition = 10
	npc1.age = 20
	npc1.max_lifespan = 200
	npc1.aptitude = 60

	var npc2 = CharacterData.new()
	npc2.npc_name = "龙傲天 [狂热野心]"
	npc2.trait_cautious = 10
	npc2.trait_ambition = 95
	npc2.age = 20
	npc2.max_lifespan = 200
	npc2.aptitude = 60

	var npc3 = CharacterData.new()
	npc3.npc_name = "李长寿 [寿元将尽]"
	npc3.trait_cautious = 90
	npc3.trait_ambition = 10
	npc3.age = 115
	npc3.max_lifespan = 120
	npc3.aptitude = 40

	SocialManager.npc_attributes["test_npc_1"] = npc1
	SocialManager.npc_attributes["test_npc_2"] = npc2
	SocialManager.npc_attributes["test_npc_3"] = npc3

	# 订阅日志
	if get_node("/root/MacroSimulator"):
		get_node("/root/MacroSimulator").macro_event_logged.connect(_on_log)

	# 启动闭关
	_append_log("[color=yellow]--- 开始闭关 100 年演算 ---[/color]")
	TimeManager.skip_time(100 * 365 * 24.0)

	# 如果是命令行模式，延迟1秒后退出
	if DisplayServer.get_name() == "headless":
		get_tree().quit()

func _on_log(msg: String) -> void:
	_append_log(msg)

func _append_log(msg: String) -> void:
	if log_label:
		log_label.append_text(msg + "\n")
	else:
		print(msg)
