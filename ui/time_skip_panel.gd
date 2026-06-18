extends CanvasLayer

var is_open: bool = false
var skip_days_spinbox: SpinBox

func _ready() -> void:
	layer = 100
	visible = false
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "=== 闭关岁月 ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var label = Label.new()
	label.text = "闭关天数: "
	hbox.add_child(label)
	
	skip_days_spinbox = SpinBox.new()
	skip_days_spinbox.min_value = 1
	skip_days_spinbox.max_value = 3650 # 最多闭关10年
	skip_days_spinbox.value = 30 # 默认30天
	hbox.add_child(skip_days_spinbox)
	
	var btn_skip = Button.new()
	btn_skip.text = "开始闭关 (跃迁时间)"
	btn_skip.custom_minimum_size = Vector2(200, 50)
	btn_skip.pressed.connect(_on_skip_pressed)
	vbox.add_child(btn_skip)

	var btn_close = Button.new()
	btn_close.text = "取消"
	btn_close.pressed.connect(toggle_ui)
	vbox.add_child(btn_close)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		toggle_ui()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and is_open:
		toggle_ui()
		get_viewport().set_input_as_handled()

func toggle_ui() -> void:
	is_open = !is_open
	visible = is_open
	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_skip_pressed() -> void:
	var days = skip_days_spinbox.value
	print("[TimeSkipUI] 玩家选择闭关 ", days, " 天。")
	var hours = days * 24.0
	
	if Engine.get_main_loop().root.has_node("TimeManager"):
		var tm = Engine.get_main_loop().root.get_node("TimeManager")
		tm.skip_time(hours)
	
	toggle_ui()
