extends CanvasLayer

@onready var main_panel = $MainPanel
@onready var log_output = $MainPanel/VBoxContainer/HBoxContainer/LogOutput

@onready var btn_logs = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnLogs
@onready var btn_social = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnSocial
@onready var btn_time = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnTime
@onready var btn_entities = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnEntities
@onready var btn_items = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnItems
@onready var btn_factions = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnFactions
@onready var btn_clear = $MainPanel/VBoxContainer/HBoxContainer/SideBar/BtnClear

var recent_logs: String = ""
var is_viewing_logs: bool = true

# =====================================================
# 命令注册表 (Command Registry) — 所有可用指令的元数据
# =====================================================
var command_registry: Array[Dictionary] = [
	{"cmd": "help",        "args": "",              "desc": "显示所有可用指令列表"},
	{"cmd": "spawn_sects", "args": "[count]",       "desc": "强制触发宗门降世（默认5个）"},
	{"cmd": "test_mode",   "args": "<0|1>",         "desc": "开关测试模式（1=无限道具/无视地形）"},
	{"cmd": "tp",          "args": "<x> <y> <z>",   "desc": "传送玩家到指定世界坐标"},
	{"cmd": "god",         "args": "",              "desc": "切换无敌模式（满血满蓝不受伤）"},
	{"cmd": "give",        "args": "<物品ID> [数量]", "desc": "给予玩家指定物品"},
	{"cmd": "time",        "args": "<天数>",         "desc": "快进指定天数"},
	{"cmd": "speed",       "args": "<倍率>",         "desc": "设置游戏速度倍率（1.0=正常）"},
	{"cmd": "kill_all",    "args": "",              "desc": "清除当前场景所有NPC实体"},
	{"cmd": "clear",       "args": "",              "desc": "清空控制台日志"},
	{"cmd": "list_sects",  "args": "",              "desc": "列出所有已生成宗门及其阵眼坐标"},
]

# 自动补全UI组件引用
var command_input: LineEdit
var autocomplete_list: ItemList

func _ready() -> void:
	main_panel.hide()
	
	# 添加拖拽行为
	var dragger = Node.new()
	dragger.set_script(load("res://0000core/ui/draggable_behavior.gd"))
	main_panel.add_child(dragger)
	
	btn_logs.pressed.connect(_show_logs)
	btn_social.pressed.connect(_dump_social_graph)
	btn_time.pressed.connect(_dump_time_engine)
	btn_entities.pressed.connect(_dump_entities)
	btn_items.pressed.connect(_dump_items)
	btn_factions.pressed.connect(_dump_factions)
	btn_clear.pressed.connect(_clear_logs)
	
	# --- 命令输入框 ---
	command_input = LineEdit.new()
	command_input.placeholder_text = "输入指令... (输入 help 查看所有命令)"
	command_input.custom_minimum_size = Vector2(0, 36)
	command_input.add_theme_font_size_override("font_size", 16)
	$MainPanel/VBoxContainer.add_child(command_input)
	command_input.text_submitted.connect(_on_command_submitted)
	command_input.text_changed.connect(_on_input_text_changed)
	
	# --- 自动补全下拉菜单 ---
	autocomplete_list = ItemList.new()
	autocomplete_list.custom_minimum_size = Vector2(0, 0)
	autocomplete_list.max_columns = 1
	autocomplete_list.auto_height = true
	autocomplete_list.allow_reselect = true
	autocomplete_list.visible = false
	# 半透明深色背景
	autocomplete_list.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.12, 0.05, 0.95)
	style.border_color = Color(0.3, 0.8, 0.3, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	autocomplete_list.add_theme_stylebox_override("panel", style)
	$MainPanel/VBoxContainer.add_child(autocomplete_list)
	autocomplete_list.item_activated.connect(_on_autocomplete_selected)
	
	print("[DevConsole] 上帝视角控制台已挂载，按 ` (反引号/波浪号) 呼出。输入 help 查看指令表。")

# =====================================================
# 自动补全逻辑
# =====================================================
func _on_input_text_changed(new_text: String) -> void:
	var prefix = new_text.strip_edges().to_lower()
	autocomplete_list.clear()
	
	if prefix == "":
		autocomplete_list.visible = false
		return
	
	var matches: Array[Dictionary] = []
	for entry in command_registry:
		if entry.cmd.begins_with(prefix):
			matches.append(entry)
	
	if matches.size() == 0 or (matches.size() == 1 and matches[0].cmd == prefix):
		autocomplete_list.visible = false
		return
	
	for m in matches:
		var display = m.cmd
		if m.args != "":
			display += "  " + m.args
		display += "   — " + m.desc
		autocomplete_list.add_item(display)
	
	autocomplete_list.visible = true

func _on_autocomplete_selected(idx: int) -> void:
	if idx < 0 or idx >= command_registry.size():
		return
	# 从显示文本中提取命令名
	var text = autocomplete_list.get_item_text(idx)
	var cmd_name = text.split(" ")[0]
	command_input.text = cmd_name + " "
	command_input.caret_column = command_input.text.length()
	autocomplete_list.visible = false
	command_input.grab_focus()

# Tab 键补全
func _unhandled_input(event: InputEvent) -> void:
	if not main_panel.visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if autocomplete_list.visible and autocomplete_list.item_count > 0:
			var text = autocomplete_list.get_item_text(0)
			var cmd_name = text.split(" ")[0]
			command_input.text = cmd_name + " "
			command_input.caret_column = command_input.text.length()
			autocomplete_list.visible = false
			command_input.grab_focus()
			get_viewport().set_input_as_handled()

# =====================================================
# 命令解析与执行
# =====================================================
func _on_command_submitted(cmd: String) -> void:
	command_input.text = ""
	autocomplete_list.visible = false
	
	var parts = cmd.strip_edges().split(" ", false)
	if parts.size() == 0:
		return
		
	var command = parts[0].to_lower()
	var args = parts.slice(1)
	
	log_text("> " + cmd, "lime")
	
	match command:
		"help":
			_execute_help()
		"spawn_sects":
			var count = 5
			if args.size() > 0 and args[0].is_valid_int():
				count = args[0].to_int()
			var fm = get_node_or_null("/root/FactionManager")
			if fm and fm.has_method("seed_initial_world"):
				fm.seed_initial_world(count)
				log_text("已触发宗门降世，数量: " + str(count), "green")
			else:
				log_text("错误: FactionManager 未找到", "red")
		"test_mode":
			if args.size() > 0:
				var val = args[0] == "1" or args[0].to_lower() == "true"
				var ws = get_node_or_null("/root/WorldState")
				if ws:
					ws.test_mode = val
					log_text("test_mode 已设为: " + str(val), "cyan")
			else:
				log_text("用法: test_mode <0|1>", "yellow")
		"tp":
			if args.size() >= 3:
				var target_pos = Vector3(args[0].to_float(), args[1].to_float(), args[2].to_float())
				var player = get_tree().get_first_node_in_group("player")
				if player == null:
					player = get_node_or_null("/root/GameRoot/Player")
				if player:
					player.global_position = target_pos
					log_text("已传送至: " + str(target_pos), "cyan")
				else:
					log_text("错误: 找不到玩家实体", "red")
			else:
				log_text("用法: tp <x> <y> <z>", "yellow")
		"god":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var stats = player.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
				if stats:
					stats.current_health = stats.max_health
					stats.current_mana = stats.max_mana
					log_text("无敌模式：气血灵力已灌满！", "gold")
				else:
					log_text("玩家缺少 Stats 组件", "red")
		"give":
			if args.size() >= 1:
				var item_id = args[0]
				var qty = 1
				if args.size() >= 2 and args[1].is_valid_int():
					qty = args[1].to_int()
				var player = get_tree().get_first_node_in_group("player")
				if player:
					var inv = player.get_node_or_null("Inventory")
					if inv and inv.has_method("add_item"):
						inv.add_item(item_id, qty)
						log_text("已给予: " + item_id + " x" + str(qty), "green")
					else:
						log_text("玩家背包组件缺失", "red")
			else:
				log_text("用法: give <物品ID> [数量]", "yellow")
		"time":
			if args.size() >= 1 and args[0].is_valid_int():
				var days = args[0].to_int()
				var tm = get_node_or_null("/root/TimeManager")
				if tm and tm.has_method("skip_days"):
					tm.skip_days(days)
					log_text("已快进 " + str(days) + " 天", "cyan")
				else:
					log_text("TimeManager 不存在或缺少 skip_days 方法", "red")
			else:
				log_text("用法: time <天数>", "yellow")
		"speed":
			if args.size() >= 1 and args[0].is_valid_float():
				Engine.time_scale = args[0].to_float()
				log_text("游戏速度设为: " + str(Engine.time_scale) + "x", "cyan")
			else:
				log_text("用法: speed <倍率>  (例: speed 5.0)", "yellow")
		"kill_all":
			var npcs = get_tree().get_nodes_in_group("npc")
			for npc in npcs:
				npc.queue_free()
			log_text("已清除 " + str(npcs.size()) + " 个NPC实体", "orange")
		"clear":
			_clear_logs()
		"list_sects":
			_execute_list_sects()
		_:
			log_text("未知指令: " + command + "  (输入 help 查看可用命令)", "red")

func _execute_help() -> void:
	log_text("==================== 控制台指令手册 ====================", "gold")
	for entry in command_registry:
		var line = "[color=lime]" + entry.cmd + "[/color]"
		if entry.args != "":
			line += " [color=gray]" + entry.args + "[/color]"
		line += "  —  [color=white]" + entry.desc + "[/color]"
		log_output.text += "\n" + line

func _execute_list_sects() -> void:
	var fm = get_node_or_null("/root/FactionManager")
	if not fm or fm.active_factions.is_empty():
		log_text("当前世界暂无宗门", "yellow")
		return
	log_text("--- 已生成宗门列表 ---", "gold")
	var headers = ["宗门名称", "阵营", "阵眼坐标", "等级"]
	var rows = []
	for sect_id in fm.active_factions:
		var f: FactionData = fm.active_factions[sect_id]
		var align = ["正道", "魔道", "中立"][f.alignment] if f.alignment >= 0 and f.alignment <= 2 else "?"
		rows.append([f.faction_name, align, str(f.core_world_pos), str(f.level)])
	log_table(4, headers, rows)

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
		command_input.grab_focus()
	else:
		# 关闭控制台时，必须把鼠标锁回游戏中心！否则 player 会丢弃所有点击事件！
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		autocomplete_list.visible = false

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
		var data = sm.npc_attributes[id] as CharacterData
		if data == null: continue
		var faction_name = data.faction.faction_name if data.faction else "无名"
		var align = data.faction.alignment if data.faction else 2
		var wealth = data.need_resource * 10 if data else 0
		npc_rows.append([
			id, 
			data.npc_name, 
			str(data.cultivation_comp.cultivation_realm), 
			data.faction_id, 
			"无", # personality_tags moved or missing
			data.current_action, 
			str(wealth)
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
		var stats = player.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
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
		var uses = meta.uses
		var uses_str = "无限" if uses == -1 else str(uses)
		rows.append([
			id,
			meta.icon,
			meta.type,
			uses_str,
			str(meta.is_catalyst),
			str(meta.get_effects())
		])
	log_table(6, headers, rows)

func _dump_factions() -> void:
	log_text("====================", "pink")
	log_text(">> 导出【FactionManager】宗门派系库", "pink")
	
	if not get_node_or_null("/root/FactionManager"):
		log_text("错误: 找不到 FactionManager", "red")
		return
		
	if FactionManager.active_factions.is_empty():
		log_text("当前世界暂无任何宗门诞生。")
		return
		
	var headers = ["宗门ID", "名称", "阵营", "等级", "资源储备", "总战力", "门徒数", "任务数"]
	var rows = []
	for sect_id in FactionManager.active_factions:
		var faction: FactionData = FactionManager.active_factions[sect_id]
		var align_str = ["正道", "魔道", "中立"][faction.alignment] if faction.alignment >= 0 and faction.alignment <= 2 else "未知"
		rows.append([
			sect_id,
			faction.faction_name,
			align_str,
			str(faction.level),
			str(faction.power.resource_reserves),
			str(faction.power.total_combat_power),
			str(faction.members.size()),
			str(faction.task_pool.size())
		])
	log_table(8, headers, rows)
