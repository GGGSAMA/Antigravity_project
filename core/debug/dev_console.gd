extends CanvasLayer

@onready var main_panel = $MainPanel
@onready var log_output = $MainPanel/VBoxContainer/HBoxContainer/LogOutput

@onready var btn_logs = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnLogs
@onready var btn_social = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnSocial
@onready var btn_time = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnTime
@onready var btn_entities = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnEntities
@onready var btn_items = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnItems
@onready var btn_clear = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnClear

var recent_logs: String = ""
var is_viewing_logs: bool = true

func _ready() -> void:
	main_panel.hide()
	
	btn_logs.pressed.connect(_show_logs)
	btn_social.pressed.connect(_dump_social_graph)
	btn_time.pressed.connect(_dump_time_engine)
	btn_entities.pressed.connect(_dump_entities)
	btn_items.pressed.connect(_dump_items)
	btn_clear.pressed.connect(_clear_logs)
	
	print("[DevConsole] 上帝视角控制台已挂载，按 ` (反引号/波浪号) 呼出。")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# KEY_QUOTELEFT is the ` / ~ key
		if event.keycode == KEY_QUOTELEFT:
			_toggle_console()
			get_viewport().set_input_as_handled()

func _toggle_console() -> void:
	main_panel.visible = not main_panel.visible
	if main_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		# If other UIs are not open, this might be needed. 
		# But since this is an overlay, we just let Godot or HUDManager handle the default capture if needed.
		pass

func _show_logs() -> void:
	is_viewing_logs = true
	log_output.text = recent_logs

func log_from_manager(text: String, color: String = "white") -> void:
	var bb = "\n[color=" + color + "]" + text + "[/color]"
	recent_logs += bb
	# 防止内存爆炸
	if recent_logs.length() > 50000:
		recent_logs = recent_logs.right(30000)
	if is_viewing_logs:
		log_output.text += bb

func log_text(text: String, color: String = "white") -> void:
	is_viewing_logs = false
	log_output.text += "\n[color=" + color + "]" + text + "[/color]"

func log_table(columns: int, headers: Array, rows: Array) -> void:
	is_viewing_logs = false
	var bb = "\n[table=" + str(columns) + "]"
	for h in headers:
		bb += "[cell][color=orange]" + str(h) + "[/color][/cell]"
	for row in rows:
		for cell in row:
			bb += "[cell]" + str(cell) + "[/cell]"
	bb += "[/table]"
	log_output.text += bb

func _clear_logs() -> void:
	log_output.text = ""
	if is_viewing_logs:
		recent_logs = ""

func _dump_social_graph() -> void:
	log_text("====================", "yellow")
	log_text(">> 导出【SocialManager】网络拓扑", "yellow")
	var sm = get_node_or_null("/root/SocialManager")
	if not sm:
		log_text("错误: 找不到 SocialManager", "red")
		return
		
	log_text("--- NPC 属性字典 ---", "green")
	var npc_headers = ["ID", "姓名", "境界", "阵营", "性格标签", "状态", "财富"]
	var npc_rows = []
	for id in sm.npc_attributes:
		var data = sm.npc_attributes[id]
		npc_rows.append([
			id, 
			data.get("name", ""), 
			str(data.get("cultivation", "")), 
			str(data.get("alignment", "")), 
			str(data.get("personality_tags", [])), 
			data.get("status", ""), 
			str(data.get("wealth", 0))
		])
	log_table(7, npc_headers, npc_rows)
	
	log_text("\n--- 稀疏关系图谱 ---", "green")
	var rel_headers = ["发起人", "目标", "好感度", "恐惧值", "羁绊标签", "历史结怨记录"]
	var rel_rows = []
	for src_id in sm.relationships:
		var targets = sm.relationships[src_id]
		for tgt_id in targets:
			var data = targets[tgt_id]
			rel_rows.append([
				src_id, 
				tgt_id, 
				str(data.get("affinity", 0)), 
				str(data.get("fear", 0)), 
				str(data.get("tags", [])), 
				str(data.get("history_logs", []))
			])
	log_table(6, rel_headers, rel_rows)

func _dump_time_engine() -> void:
	log_text("====================", "cyan")
	log_text(">> 导出【TimeManager】时间状态", "cyan")
	var tm = get_node_or_null("/root/TimeManager")
	if not tm:
		log_text("错误: 找不到 TimeManager", "red")
		return
		
	var headers = ["当前历法", "总流逝天数", "是否倍速", "剩余跳过天数"]
	var rows = [[
		tm.get_formatted_time_string(), 
		str(tm.get_current_day()), 
		"N/A (Instant Skip)", 
		"N/A"
	]]
	log_table(4, headers, rows)

func _dump_entities() -> void:
	log_text("====================", "purple")
	log_text(">> 导出【实体属性与状态】", "purple")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		log_text("--- 玩家 (Player) ---", "green")
		var stats = player.get_node_or_null("Stats")
		if stats:
			var headers = ["生命值", "法力值", "境界层级", "修为点数", "灵石储备"]
			var rows = [[
				str(stats.current_health) + "/" + str(stats.max_health),
				str(stats.current_mana) + "/" + str(stats.max_mana),
				str(stats.get("cultivation_level")),
				str(stats.get("cultivation_points")),
				str(stats.get("spirit_stones"))
			]]
			log_table(5, headers, rows)
		else:
			log_text("玩家缺少 Stats 组件")
	else:
		log_text("未检测到玩家")

func _dump_items() -> void:
	log_text("====================", "orange")
	log_text(">> 导出【ItemDatabase】物品字典 (表格化)", "orange")
	
	# ItemDatabase 已经注册了 class_name，并且具备 static 属性
	ItemDatabase._load_if_empty()
	
	if not "ITEMS" in ItemDatabase or ItemDatabase.ITEMS.is_empty():
		log_text("错误: 物品数据库为空或未加载", "red")
		return
		
	var headers = ["物品ID (Name)", "图标", "类型 (Type)", "耐久/次数", "是否法器", "特殊效果 (Effects)"]
	var rows = []
	for id in ItemDatabase.ITEMS:
		var meta = ItemDatabase.ITEMS[id]
		var uses = meta.get("uses", 1)
		var uses_str = "无限" if uses == -1 else str(uses)
		rows.append([
			id,
			meta.get("icon", ""),
			meta.get("type", ""),
			uses_str,
			str(meta.get("is_catalyst", false)),
			str(meta.get("effects", {}))
		])
	log_table(6, headers, rows)
