extends Node

# ==============================================================================
# 【叙事导演 (Narrative Director)】
# 职责：严格贯彻《AGENTS.md》中的最高指导思想 ——“角色演绎代入法”。
# 监听事件总线的关键节点，将冷冰冰的数字和逻辑，转化为角色充满情绪张力的“内心独白日志”或“气泡弹窗”，
# 强行拉扯玩家的代入感。
# ==============================================================================

func _ready():
	var eb = Engine.get_main_loop().root.get_node_or_null("EventBus")
	if eb:
		# 连接自定义事件
		eb.connect("narrative_event", Callable(self, "_on_narrative_event"))
	else:
		push_error("NarrativeDirector: 找不到 EventBus，请检查 Autoload 顺序")

func _on_narrative_event(event_type: String, victim: CharacterData, attacker: CharacterData, context: Variant):
	match event_type:
		"vowed_revenge":
			_handle_vowed_revenge(victim, attacker)
		"tragic_accident":
			_handle_tragic_accident(victim, attacker)
		"grudge_formed":
			_handle_grudge(victim, attacker)
		_:
			pass

func _handle_vowed_revenge(victim: CharacterData, attacker: CharacterData):
	var text = "【角色绝笔日记】“%s！今日废我道基之仇，已刻于神魂！他日我若神功大成，定叫你求生不得，求死不能！”" % attacker.npc_name
	_print_and_log(victim, text, "BLOOD_FEUD")

func _handle_tragic_accident(victim: CharacterData, attacker: CharacterData):
	# 注意：这里的 victim 是受伤者，attacker 是感到内疚的误伤者（比如大师姐）
	var text_victim = "【角色残卷日记】“为什么... %s... 为什么会是你？罢了，这就是命吗...”" % attacker.npc_name
	_print_and_log(victim, text_victim, "DESPAIR")

	var text_attacker = "【%s的凄楚独白】“不！我究竟做了什么... 就算寻遍天涯海角，我也一定要找到九转还魂丹救你！”" % attacker.npc_name
	_print_and_log(attacker, text_attacker, "EXTREME_GUILT")

func _handle_grudge(victim: CharacterData, attacker: CharacterData):
	var text = "【角色日常手记】“晦气！遇到个叫 %s 的疯子，这梁子算是结下了，以后见一次躲一次！”" % attacker.npc_name
	_print_and_log(victim, text, "ANNOYED")

# 将日志写入控制台，并推送到 MacroSimulator 进行广播
func _print_and_log(npc: CharacterData, text: String, emotion_tag: String):
	print("\n>>> 角色演绎系统触发 [" + emotion_tag + "] <<<")
	print(text)
	print("------------------------------------------------")

	# 追加写入人生履历 (Level 3 代表改变人生的极高亮事件)
	if npc.get("history_trajectory") != null:
		npc.history_trajectory.append({"age": npc.age, "text": text, "level": 3, "type": emotion_tag})

	# 如果有宏观事件广播器，将其推送到游戏内 UI 上
	var ms = Engine.get_main_loop().root.get_node_or_null("MacroSimulator")
	if ms and ms.has_signal("macro_event_logged"):
		ms.emit_signal("macro_event_logged", "[骨龄%d岁] %s" % [npc.age, text])
