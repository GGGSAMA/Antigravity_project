extends PanelContainer
class_name ItemContextMenu

signal action_selected(action_name: String, slot_idx: int)

var vbox: VBoxContainer
var slot_idx: int = -1
var item_data = null
var manager = null

func _ready() -> void:
	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# 设置面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.28, 0.2, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	add_theme_stylebox_override("panel", style)
	
	# 点击外部区域关闭菜单
	set_process_input(true)
	
	# 确保在最顶层渲染
	z_index = 100

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var local_mouse_pos = get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, size)
		if not rect.has_point(local_mouse_pos):
			# 点击在了菜单外部，关闭菜单并消费这个点击，防止误触后面的格子
			queue_free()
			get_viewport().set_input_as_handled()

func setup(p_slot_idx: int, p_item_data, p_manager) -> void:
	slot_idx = p_slot_idx
	item_data = p_item_data
	manager = p_manager
	
	for child in vbox.get_children():
		child.queue_free()
		
	if not item_data:
		return
		
	var ItemDatabase = load("res://0000core/data/item_database.gd")
	var meta = ItemDatabase.get_item(item_data.get_item_id())
	var type = meta.type
	
	# 动态生成按钮
	if type == "potion" or type == "consumable" or type == "artifact":
		_add_button("使用 / 服下", "use")
	elif type == "weapon" or type == "armor":
		_add_button("装 备", "equip")
		
	_add_button("丢 弃", "drop")
	
func _add_button(text: String, action_name: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(100, 30)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.1, 0.9)
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.2, 0.15, 1)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.25, 0.18, 1)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.pressed.connect(func():
		action_selected.emit(action_name, slot_idx)
		queue_free()
	)
	vbox.add_child(btn)
