extends "res://0000core/ui/base_menu_ui.gd"
class_name SpellWheelUI

@onready var selected_name_label: Label = $Center/SelectedName

var is_open: bool = false
var spells: Array = []
var is_left_hand: bool = true

var hovered_index: int = -1
var radius_inner: float = 60.0
var radius_outer: float = 160.0

signal spell_selected(spell_id: String)

func _ready() -> void:
	super._ready()
	set_process_input(false)
	set_process(false)

func open_wheel(is_left: bool = false) -> void:
	is_left_hand = is_left
	spells.clear()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var spell_comp = player.get("spells")
		if spell_comp:
			var arr = spell_comp.left_spells if is_left else spell_comp.right_spells
			var SpellDatabase = preload("res://00020components/spell_database.gd")
			for spell_id in arr:
				var data = SpellDatabase.get_spell(spell_id)
				spells.append({"name": data.get("name", "Unknown"), "icon": data.get("icon", "❓"), "id": spell_id})
	
	if spells.is_empty():
		spells.append({"name": "无法术", "icon": "❌", "id": ""})
		
	# 强行填充到 5 个槽位（五边形）
	while spells.size() < 5:
		spells.append({"name": "空位", "icon": "", "id": ""})
	if spells.size() > 5:
		spells.resize(5)

	is_open = true
	open_ui()
	set_process_input(true)
	set_process(true)
	hovered_index = -1
	
	# Force mouse to center of screen
	var viewport_size = get_viewport_rect().size
	get_viewport().warp_mouse(viewport_size / 2.0)
	
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN # Hide but confine to window

func close_wheel() -> void:
	if not is_open: return
	is_open = false
	close_ui()
	set_process_input(false)
	set_process(false)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if hovered_index == -1:
		spell_selected.emit("CLEAR")
	elif hovered_index >= 0 and hovered_index < spells.size():
		var selected_id = spells[hovered_index]["id"]
		if selected_id == "":
			spell_selected.emit("CLEAR")
		else:
			spell_selected.emit(selected_id)

func _input(event: InputEvent) -> void:
	if not is_open: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var selected_id = "CLEAR"
		if hovered_index >= 0 and hovered_index < spells.size():
			if spells[hovered_index]["id"] != "":
				selected_id = spells[hovered_index]["id"]
		
		# 关闭并重置状态
		is_open = false
		hide()
		set_process_input(false)
		set_process(false)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		spell_selected.emit(selected_id)
		# 消耗此点击事件，防止传到战斗底层
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not is_open: return
	
	var mouse_pos = get_global_mouse_position()
	var center = get_viewport_rect().size / 2.0
	var offset = mouse_pos - center
	
	if offset.length() < radius_inner:
		hovered_index = -1
		selected_name_label.text = "取消选择"
	else:
		var angle = offset.angle()
		var num_spells = spells.size()
		var slice_angle = PI * 2.0 / num_spells
		
		# Offset so index 0 is at the top (-PI/2)
		var rotated_angle = angle - (-PI / 2.0)
		var normalized_angle = fposmod(rotated_angle + slice_angle / 2.0, PI * 2.0)
		hovered_index = int(normalized_angle / slice_angle) % num_spells
		
		selected_name_label.text = spells[hovered_index]["name"]
		
	queue_redraw()

func _draw() -> void:
	if not is_open: return
	
	var center = get_viewport_rect().size / 2.0
	var num_spells = spells.size()
	if num_spells == 0: return
	
	var slice_angle = PI * 2.0 / num_spells
	
	for i in range(num_spells):
		# Index 0 is Top
		var mid_angle = -PI / 2.0 + i * slice_angle
		var start_angle = mid_angle - slice_angle / 2.0
		var end_angle = mid_angle + slice_angle / 2.0
		
		var is_hovered = (i == hovered_index)
		var color = Color(0.2, 0.4, 0.8, 0.6) if is_hovered else Color(0.1, 0.1, 0.15, 0.8)
		
		# 使用直线连接 (五边形)
		_draw_pie_slice(center, radius_inner, radius_outer, start_angle, end_angle, color)
		
		# Draw Icon Text
		if spells[i]["icon"] != "":
			var icon_pos = center + Vector2(cos(mid_angle), sin(mid_angle)) * ((radius_inner + radius_outer) / 2.0)
			var font = ThemeDB.fallback_font
			draw_string(font, icon_pos - Vector2(10, -5), spells[i]["icon"], HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)

	# 绘制中心的取消 X 区域
	var center_color = Color(0.8, 0.2, 0.2, 0.8) if hovered_index == -1 else Color(0.1, 0.1, 0.1, 0.8)
	draw_circle(center, radius_inner, center_color)
	draw_arc(center, radius_inner, 0, PI*2, 32, Color(0.8, 0.8, 0.8, 0.5), 2.0)
	
	var font = ThemeDB.fallback_font
	draw_string(font, center - Vector2(8, -8), "X", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)

func _draw_pie_slice(center: Vector2, r_in: float, r_out: float, start_a: float, end_a: float, color: Color) -> void:
	var points = PackedVector2Array()
	# num_segments = 1 强制将外围画成直线，五边形效果
	var num_segments = 1
	var angle_step = (end_a - start_a) / num_segments
	
	for j in range(num_segments + 1):
		var a = start_a + j * angle_step
		points.append(center + Vector2(cos(a), sin(a)) * r_out)
	
	for j in range(num_segments, -1, -1):
		var a = start_a + j * angle_step
		points.append(center + Vector2(cos(a), sin(a)) * r_in)
		
	draw_polygon(points, PackedColorArray([color]))
	
	# Draw border lines
	var border_color = Color(0.8, 0.6, 0.1, 0.5)
	draw_polyline(points, border_color, 2.0, true)

