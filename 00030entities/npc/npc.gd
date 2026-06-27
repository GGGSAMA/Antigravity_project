extends CharacterBody3D

@export var data: CharacterData
var is_passive: bool = true

@onready var name_tag = $NameTag
@onready var stats = $ActorDataTemplate/CombatRuntimeAttr
@onready var player_model = $PlayerModel

func _ready() -> void:
	# The fem_warrior model is loaded directly via npc.tscn PlayerModel.
	pass # 转移到 setup_from_data 中执行数据同步


	# 延迟初始化 AI
	call_deferred("_init_ai")
	# 新增全局死亡监听
	if Engine.get_main_loop().root.has_node("EventBus"):
		Engine.get_main_loop().root.get_node("EventBus").npc_died.connect(_on_death_event)

# ==============================================================================
# 虚实数据单向注入 (Optimization 3)
# ==============================================================================
func setup_from_data(new_data: CharacterData) -> void:
	self.data = new_data
	if not self.data: return

	# 强制同步数据到前台
	refresh_from_data()

	# TODO: 这里可依据残血、暴富状态设置模型受损贴图或特效
	if stats and stats.current_health < stats.max_health * 0.3:
		# 比如触发受伤特效
		pass

func _on_death_event(d: CharacterData, cause: String) -> void:
	if data and d.npc_id == data.npc_id:
		print("[NPC] 接收到死亡事件：", data.npc_name, " 死因：", cause)
		# 取消所有行为
		set_physics_process(false)

		# 临时使用缩小和变暗来替代倒地动画
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 1.5)

		# 生成储物袋
		if cause == "combat" or cause == "old_age":
			_spawn_loot_bag()

		tween.tween_callback(queue_free)

func _spawn_loot_bag() -> void:
	var loot_scene = load("res://00030entities/interactables/items/loot_bag.tscn")
	if loot_scene:
		var bag = loot_scene.instantiate()
		bag.money = data.need_resource * 100 # 临时用需财度代替金钱
		# bag.inventory = data.inventory

		var parent = get_parent()
		if parent:
			parent.add_child(bag)
			bag.global_position = global_position + Vector3(0, 0.5, 0)
			print("[NPC] 掉落了储物袋！")

# ----------------- AI 状态与神识机制 (LimboAI) -----------------
var affinity: int = 0
var target_player: Node3D = null

# LimboAI 组件
var hsm: Node
var blackboard: RefCounted

func _init_ai() -> void:
	if data:
		if data.npc_name == "李逍遥": affinity = 100
		elif data.npc_name == "血老怪": affinity = -100
		else: affinity = 0

	# 动态构建 LimboHSM 状态机 (由于是在无编辑器的代码环境，这里手动实例化 Node 模拟 HSM 的控制流)
	# 如果用户本地有具体的 LimboState 脚本，可以直接挂载。这里为了通用性，采用极简代码路由架构

	if ClassDB.class_exists("LimboHSM"):
		print("[NPC] LimboAI 已加载，初始化 HSM...")
		hsm = ClassDB.instantiate("LimboHSM")
		hsm.name = "Brain"
		add_child(hsm)

		# 尝试获取黑板
		if hsm.has_method("get_blackboard"):
			blackboard = hsm.get_blackboard()
			if blackboard and blackboard.has_method("set_var"):
				blackboard.set_var("ai_state", "idle")
	else:
		print("[NPC] 未检测到 LimboHSM 原生类，降级为内置简单状态机。")
		hsm = Node.new()
		hsm.set_meta("ai_state", "idle")
		add_child(hsm)

func _set_state(state: String) -> void:
	if blackboard and blackboard.has_method("set_var"):
		blackboard.set_var("ai_state", state)
	elif hsm:
		hsm.set_meta("ai_state", state)

func _get_state() -> String:
	if blackboard and blackboard.has_method("get_var"):
		return blackboard.get_var("ai_state", "idle")
	elif hsm and hsm.has_meta("ai_state"):
		return hsm.get_meta("ai_state")
	return "idle"

func on_being_spied(scanner: Node, is_provoked: bool) -> void:
	if not is_inside_tree(): return

	target_player = scanner as Node3D

	if is_provoked:
		if has_node("/root/Log"): get_node("/root/Log").warn("NPC", data.npc_name + " 被低阶神识窥探，大怒！")
		if affinity < 0:
			_set_state("attack")
			_show_bubble("蝼蚁！敢用神识窥探老夫？！找死！", Color.RED)
		else:
			_set_state("idle")
			_show_bubble("哼，念你初犯，下不为例！", Color.YELLOW)
	else:
		if affinity >= 50:
			_set_state("approach")
			_show_bubble("道友，神识传音可是有事相商？", Color.GREEN)
		elif affinity < -50:
			_set_state("attack")
			_show_bubble("既然被你发现了，那就留下吧！", Color.RED)
		else:
			_set_state("idle")
			_show_bubble("哪来的道友在此窥探？", Color.WHITE)

func _show_bubble(text: String, color: Color) -> void:
	name_tag.text = text
	name_tag.modulate = color
	var tween = create_tween()
	tween.tween_callback(func(): refresh_from_data(); name_tag.modulate = Color.WHITE).set_delay(4.0)

func take_damage(amount: int, source_pos: Vector3 = Vector3.ZERO) -> void:
	if not data or not data.is_alive: return
	data.stamina -= amount
	_show_bubble("啊！何方道友偷袭！", Color.RED)
	if data.stamina <= 0:
		data.stamina = 0
		if Engine.get_main_loop().root.has_node("DeathManager"):
			Engine.get_main_loop().root.get_node("DeathManager").process_death(data, "combat", self)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	var is_moving = false
	var current_state = _get_state()
	var override_macro = false

	if data and data.current_action != "":
		if data.current_action in ["修炼", "闭关修炼", "疗伤"]:
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)
			override_macro = true
			is_moving = false
			_set_state("idle")

			if not has_meta("is_meditating"):
				set_meta("is_meditating", true)
				var tween = create_tween()
				if player_model:
					tween.tween_property(player_model, "scale", Vector3(1.0, 0.6, 1.0), 0.5)
		elif data.current_action in ["打猎", "社交"]:
			if has_meta("is_meditating"):
				remove_meta("is_meditating")
				var tween = create_tween()
				if player_model:
					tween.tween_property(player_model, "scale", Vector3(1.0, 1.0, 1.0), 0.5)

			override_macro = true
			if not has_meta("wander_target") or global_position.distance_to(get_meta("wander_target")) < 1.0:
				var r_pos = global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
				set_meta("wander_target", r_pos)
				set_meta("wander_wait", 2.0)

			var wait_time = get_meta("wander_wait")
			if wait_time != null and wait_time > 0:
				set_meta("wander_wait", wait_time - delta)
				velocity.x = move_toward(velocity.x, 0, delta * 10.0)
				velocity.z = move_toward(velocity.z, 0, delta * 10.0)
				is_moving = false
			else:
				var target = get_meta("wander_target")
				var dir = global_position.direction_to(target)
				dir.y = 0
				velocity.x = dir.x * 2.0
				velocity.z = dir.z * 2.0
				look_at(global_position + dir, Vector3.UP)
				is_moving = true
				if randf() < 0.005: # Occasional wait
					set_meta("wander_wait", randf_range(1.0, 3.0))

	if not override_macro:
		if has_meta("is_meditating"):
			remove_meta("is_meditating")
			var tween = create_tween()
			if player_model:
				tween.tween_property(player_model, "scale", Vector3(1.0, 1.0, 1.0), 0.5)

		# 行为树 / 状态机的 Execute Update 逻辑
		if current_state == "approach" and target_player:
			var dir = global_position.direction_to(target_player.global_position)
			dir.y = 0
			if global_position.distance_to(target_player.global_position) > 2.0:
				velocity.x = dir.x * 3.0
				velocity.z = dir.z * 3.0
				look_at(global_position + dir, Vector3.UP)
				is_moving = true
			else:
				velocity.x = 0
				velocity.z = 0
				_set_state("idle")
				interact(target_player)

		elif current_state == "attack" and target_player:
			var dir = global_position.direction_to(target_player.global_position)
			dir.y = 0
			if global_position.distance_to(target_player.global_position) > 1.5:
				velocity.x = dir.x * 4.5
				velocity.z = dir.z * 4.5
				look_at(global_position + dir, Vector3.UP)
				is_moving = true
			else:
				velocity.x = 0
				velocity.z = 0
				if has_node("/root/Log"): get_node("/root/Log").warn("Combat", data.npc_name + " 对你发起了攻击！")
				if player_model and player_model.has_method("set_animation_state"):
					player_model.set_animation_state("attack")
				_set_state("idle")
		else:
			if velocity.length() > 0.1:
				is_moving = true
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)

	move_and_slide()

	if player_model and player_model.has_method("set_animation_state"):
		if is_moving:
			if velocity.length() > 3.5:
				player_model.set_animation_state("run")
			else:
				player_model.set_animation_state("walk")
		else:
			var is_attacking = false
			if player_model.get("anim_player") and player_model.anim_player:
				var curr = player_model.anim_player.current_animation.to_lower()
				if ("attack" in curr or "slash" in curr) and player_model.anim_player.is_playing():
					is_attacking = true
			if not is_attacking:
				player_model.set_animation_state("idle")

func interact(player: Node) -> void:
	var speaker = "神秘修士"
	if data: speaker = data.npc_name

	# 这里后续可以根据好感度/宗门配置不同的对话文本
	var text = "道友请留步。我看你骨骼惊奇，想必也是来这修仙界寻仙问道的吧？"
	var options = [
		{"text": "闲聊", "action": "chat"},
		{"text": "交易", "action": "trade"},
		{"text": "查看对方底细 (窥探面板)", "action": "view_stats"},
		{"text": "告辞", "action": "leave"}
	]

	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.start_dialogue(self, speaker, text, options)

func handle_dialogue_action(action: String) -> void:
	print("[NPC] 收到玩家对话指令: ", action)
	var dm = get_node_or_null("/root/DialogueManager")
	var speaker = data.npc_name if data else "神秘修士"

	if action == "chat":
		if dm:
			dm.start_dialogue(self, speaker, "天下熙熙皆为利来，天下攘攘皆为利往。道友想聊些什么？", [
				{"text": "打听宗门传闻", "action": "rumor"},
				{"text": "暂且不聊了", "action": "leave"}
			])
	elif action == "rumor":
		if dm:
			dm.start_dialogue(self, speaker, "最近修仙界可不太平，听说有几个大能陨落了...哎，不说了，咱们修为太低，不掺和。", [
				{"text": "告辞", "action": "leave"}
			])
	elif action == "trade":
		if dm:
			dm.start_dialogue(self, speaker, "我这儿穷得叮当响，道友还是去坊市看看吧。", [
				{"text": "告辞", "action": "leave"}
			])
	elif action == "view_stats":
		_show_debug_stats_ui()
		# 保持当前对话界面不关闭
		if dm:
			dm.start_dialogue(self, speaker, "道友，你用神识扫我作甚？！", [
				{"text": "冒犯了，告辞", "action": "leave"}
			])

func _show_debug_stats_ui() -> void:
	var panel = PanelContainer.new()
	panel.name = "NPCStatsUI"

	# 给动态面板挂载一个简易脚本，实现 ESC 关闭功能
	var script = GDScript.new()
	script.source_code = """
extends PanelContainer
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
"""
	script.reload()
	panel.set_script(script)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 2
	style.border_color = Color(0.8, 0.6, 0.2)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.custom_minimum_size = Vector2(400, 300)

	var t = "[b][color=gold]=== 神识窥探：NPC 属性面板 ===[/color][/b]\n\n"
	t += "姓名: [color=cyan]%s[/color]\n" % (data.npc_name if data else "未知")
	var realm_str = ["凡人", "炼气期", "筑基期", "金丹期", "元婴期", "化神期"]
	var r_idx = data.cultivation_comp.cultivation_realm if data and data.cultivation_comp else 1
	t += "境界: [color=purple]%s[/color]\n" % (realm_str[r_idx] if r_idx < realm_str.size() else "深不可测")
	t += "宗门: %s\n" % (data.faction.faction_name if data and data.faction else "散修")
	t += "状态: %s\n\n" % (data.current_action if data else "闲置")

	if data:
		t += "[color=orange]-- 宏观 AI 需求条 (满100) --[/color]\n"
		t += "寿元紧迫: %.1f\n" % data.need_lifespan
		t += "疗伤迫切: %.1f\n" % data.need_healing
		t += "修炼渴望: %.1f\n" % data.need_cultivation
		t += "资源追求: %.1f\n\n" % data.need_resource

		t += "[color=lightblue]-- AI 性格乘区 (0-100) --[/color]\n"
		t += "野心: %d | 谨慎: %d | 贪婪: %d\n" % [data.trait_ambition, data.trait_cautious, data.trait_greed]
		t += "仁善: %d | 社交: %d\n\n" % [data.trait_morality, data.trait_sociability]

	label.text = t
	vbox.add_child(label)

	var btn = Button.new()
	btn.text = "关闭神识窥探"
	btn.pressed.connect(func(): panel.queue_free())
	vbox.add_child(btn)

	panel.add_child(vbox)

	var ui_layer = get_node_or_null("/root/Game/UI Layer")
	if not ui_layer: ui_layer = get_tree().root

	# 居中显示
	panel.set_anchors_preset(Control.PRESET_CENTER)
	ui_layer.add_child(panel)

func refresh_from_data() -> void:
	var fac_name = "散修"
	if data.faction:
		fac_name = data.faction.faction_name

	# 改变头顶名字显示
	name_tag.text = "[" + fac_name + "] " + data.npc_name

	# 根据境界 (cultivation_realm) 给予底层属性加成
	# 炼气期=1, 筑基期=2, 金丹期=3...
	if data and data.cultivation_comp:
		data.aptitude = 10 * data.cultivation_comp.cultivation_realm
		# constitution was removed in earlier refactors, we use stamina
		data.stamina = 100 * data.cultivation_comp.cultivation_realm
		data.divine_sense = 10 * data.cultivation_comp.cultivation_realm

	# 血蓝回满
	stats.current_health = stats.max_health
	stats.current_mana = stats.max_mana

	# 赋予初始灵石
	if data and data.cultivation_comp:
		data.money = 50 * data.cultivation_comp.cultivation_realm
