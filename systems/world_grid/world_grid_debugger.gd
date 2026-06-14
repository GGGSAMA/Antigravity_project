extends CanvasLayer

var debug_label: RichTextLabel
var ai_log_label: RichTextLabel
var show_debug: bool = true
var ai_logs: Array = []

# 缓存的用于标记当前格子的 3D 边框
var _current_cell_marker: MeshInstance3D

func _ready():
	# 确保 Debug UI 永远在最上层
	layer = 128
	
	# 创建富文本标签 (网格属性) -> 移动到右上角
	debug_label = RichTextLabel.new()
	debug_label.bbcode_enabled = true
	debug_label.custom_minimum_size = Vector2(400, 300)
	debug_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	debug_label.position = Vector2(-420, 100) # 在时间 UI 之下
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_label)
	
	# 创建 AI 日志标签 (左侧靠下) -> 移动到左侧
	ai_log_label = RichTextLabel.new()
	ai_log_label.bbcode_enabled = true
	ai_log_label.custom_minimum_size = Vector2(500, 600)
	ai_log_label.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	ai_log_label.position = Vector2(20, -100)
	ai_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ai_log_label)
	
	# 连接 AI 模拟器信号
	if MacroSimulator.has_signal("macro_event_logged"):
		MacroSimulator.macro_event_logged.connect(_on_ai_logged)
	
	_create_cell_marker()

func _on_ai_logged(msg: String) -> void:
	ai_logs.append(msg)
	if ai_logs.size() > 15:
		ai_logs.pop_front()
	
	var text = "[b][color=cyan]=== 宏观 AI 天道推演日志 ===[/color][/b]\n"
	for log_msg in ai_logs:
		text += log_msg + "\n"
	ai_log_label.text = text

func _create_cell_marker():
	# 创建一个简单的 3D 边框框住当前的格子 (100x100)
	_current_cell_marker = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(100.0, 100.0)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.1) # 半透明绿色
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.2)
	mesh.material = mat
	_current_cell_marker.mesh = mesh
	
	# 让其悬浮在地面上方一点点，防止 Z-fighting
	_current_cell_marker.position.y = 0.5 
	_current_cell_marker.visible = show_debug
	add_child(_current_cell_marker)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			show_debug = !show_debug
			debug_label.visible = show_debug
			ai_log_label.visible = show_debug
			_current_cell_marker.visible = show_debug

func _process(_delta):
	if not show_debug: return
	
	# 尝试寻找玩家或摄像机作为探测中心
	var probe_pos = Vector3.ZERO
	var player = get_tree().get_first_node_in_group("player")
	if player:
		probe_pos = player.global_position
	else:
		var cam = get_viewport().get_camera_3d()
		if cam: probe_pos = cam.global_position
		else: return

	# 获取网格数据
	var grid_pos = WorldGridManager.world_to_grid(probe_pos)
	var tile = WorldGridManager.get_tile_at(grid_pos)
	
	# 更新 3D 标记框的位置 (对齐到网格中心)
	var center_pos = WorldGridManager.grid_to_world_center(grid_pos)
	if _current_cell_marker.get_parent() == self:
		_current_cell_marker.get_parent().remove_child(_current_cell_marker)
		get_tree().root.add_child(_current_cell_marker)
	_current_cell_marker.global_position = Vector3(center_pos.x, 0.5, center_pos.z)
	
	# 如果是邪修地盘，将框框变红/紫
	var mat = _current_cell_marker.mesh.material as StandardMaterial3D
	if tile.corruption_level > 0.0:
		mat.albedo_color = Color(0.6, 0.1, 0.8, 0.2)
		mat.emission = Color(0.6, 0.1, 0.8)
	else:
		mat.albedo_color = Color(0.2, 1.0, 0.2, 0.1)
		mat.emission = Color(0.2, 1.0, 0.2)
	
	# 构建 UI 文本
	var text = "[b][color=yellow]=== 世界网格调试仪 (F3隐藏) ===[/color][/b]\n"
	text += "当前世界坐标: (X: %.1f, Z: %.1f)\n" % [probe_pos.x, probe_pos.z]
	text += "所处逻辑网格: [color=cyan]%s[/color]\n\n" % str(grid_pos)
	
	text += "[color=orange]-- 自然属性 --[/color]\n"
	text += "灵气浓度 (Qi): %.2f\n" % tile.qi_density
	text += "五行地脉 (Leyline): %s\n" % _get_leyline_name(tile.leyline_element)
	text += "地貌生态 (Biome): %s\n" % tile.biome_type
	text += "资源富集度: %.1f\n" % tile.resource_richness
	
	text += "\n[color=pink]-- 政治与超自然 --[/color]\n"
	text += "宗门归属: %s\n" % (tile.owner_sect_id if tile.owner_sect_id != "" else "无主之地")
	text += "宗门控制力: %.1f\n" % tile.control_influence
	text += "腐化度/煞气 (Corruption): %.2f\n" % tile.corruption_level
	text += "天道气运 (Fortune): %.2f\n" % tile.fortune_level

	debug_label.text = text

func _get_leyline_name(val: int) -> String:
	match val:
		0: return "无属性"
		1: return "[color=gold]金脉[/color]"
		2: return "[color=green]木脉[/color]"
		3: return "[color=blue]水脉[/color]"
		4: return "[color=red]火脉[/color]"
		5: return "[color=brown]土脉[/color]"
		_: return "未知"
