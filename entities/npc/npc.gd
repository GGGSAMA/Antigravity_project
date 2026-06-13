extends CharacterBody3D

@export var data: NPCData

@onready var name_tag = $NameTag
@onready var stats = $Stats
@onready var player_model = $PlayerModel

func _ready() -> void:
	# The fem_warrior model is loaded directly via npc.tscn PlayerModel.

	if data:
		refresh_from_data()
		
	# 动态挂载神识被扫组件
	var NPCScannable = load("res://components/npc_scannable.gd")
	if NPCScannable:
		var scannable = NPCScannable.new()
		scannable.name = "ScannableComponent"
		scannable.scan_name = data.npc_name if data else "无名修士"
		scannable.scan_icon = "👤"
		scannable.scan_color = Color(0.8, 0.2, 0.8) # 紫色代表活物修士
		scannable.scan_type = 4 # NPC
		add_child(scannable)

	# 延迟初始化 AI
	call_deferred("_init_ai")

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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
		
	var is_moving = false
	var current_state = _get_state()
	
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
	
	if player_model and player_model.has_method("set_animation_state") and current_state != "attack":
		if is_moving:
			if velocity.length() > 3.5:
				player_model.set_animation_state("run")
			else:
				player_model.set_animation_state("walk")
		else:
			player_model.set_animation_state("idle")

func interact(player: Node) -> void:
	var speaker = "神秘修士"
	if data: speaker = data.npc_name
	
	# 这里后续可以根据好感度/宗门配置不同的对话文本
	var text = "道友请留步。我看你骨骼惊奇，想必也是来这修仙界寻仙问道的吧？"
	var options = [
		{"text": "闲聊", "action": "chat"},
		{"text": "交易", "action": "trade"},
		{"text": "告辞", "action": "leave"}
	]
	
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.start_dialogue(self, speaker, text, options)

func handle_dialogue_action(action: String) -> void:
	print("[NPC] 收到玩家对话指令: ", action)
	if action == "chat":
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue(self, data.npc_name if data else "神秘修士", "天下熙熙皆为利来，天下攘攘皆为利往。道友想聊些什么？", [
				{"text": "打听宗门传闻", "action": "rumor"},
				{"text": "暂且不聊了", "action": "leave"}
			])
	elif action == "rumor":
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue(self, data.npc_name if data else "神秘修士", "最近修仙界可不太平，听说有几个大能陨落了...哎，不说了，咱们修为太低，不掺和。", [
				{"text": "告辞", "action": "leave"}
			])
	elif action == "trade":
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue(self, data.npc_name if data else "神秘修士", "我这儿穷得叮当响，道友还是去坊市看看吧。", [
				{"text": "告辞", "action": "leave"}
			])

func refresh_from_data() -> void:
	var fac_name = "散修"
	if data.faction:
		fac_name = data.faction.faction_name
		
	# 改变头顶名字显示
	name_tag.text = "[" + fac_name + "] " + data.npc_name
	
	# 根据境界 (cultivation_realm) 给予底层属性加成
	# 炼气期=1, 筑基期=2, 金丹期=3...
	stats.aptitude = 10 * data.cultivation_realm
	stats.constitution = 10 * data.cultivation_realm
	stats.divine_sense = 10 * data.cultivation_realm
	
	# 强制重新计算血量蓝量上限
	stats.recalculate()
	stats.current_health = stats.max_health
	stats.current_mana = stats.max_mana
	
	# 赋予初始灵石
	stats.spirit_stones = 50 * data.cultivation_realm
