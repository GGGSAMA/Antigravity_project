extends Control

func _init():
	set_anchors_preset(PRESET_FULL_RECT)

func _ready():
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 50)

	# 左侧：大图预览 (占位)
	var portrait_bg = ColorRect.new()
	portrait_bg.custom_minimum_size = Vector2(250, 400)
	portrait_bg.color = Color(0.05, 0.05, 0.08, 0.8)

	var portrait_lbl = Label.new()
	portrait_lbl.text = "👤\n大千世界\n修士神影"
	portrait_lbl.horizontal_alignment = 1
	portrait_lbl.vertical_alignment = 1
	portrait_lbl.set_anchors_preset(PRESET_FULL_RECT)
	portrait_lbl.add_theme_font_size_override("font_size", 24)
	portrait_bg.add_child(portrait_lbl)

	hbox.add_child(portrait_bg)

	# 右侧：属性列表
	var stats_vbox = VBoxContainer.new()
	stats_vbox.custom_minimum_size = Vector2(300, 400)
	stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_vbox.add_theme_constant_override("separation", 20)

	_add_stat_row(stats_vbox, "修真境界", "筑基初期")
	_add_stat_row(stats_vbox, "气血 (Health)", "100 / 100", Color(0.9, 0.2, 0.2))
	_add_stat_row(stats_vbox, "真元 (Mana)", "100 / 100", Color(0.2, 0.6, 0.9))
	_add_stat_row(stats_vbox, "身法 (Speed)", "100")
	_add_stat_row(stats_vbox, "神识 (Divine Sense)", "50 丈")

	hbox.add_child(stats_vbox)
	add_child(hbox)

func _add_stat_row(parent: Control, title: String, value: String, color: Color = Color.WHITE):
	var row = HBoxContainer.new()

	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	var lbl_val = Label.new()
	lbl_val.text = value
	lbl_val.add_theme_color_override("font_color", color)
	lbl_val.add_theme_font_size_override("font_size", 18)

	row.add_child(lbl_title)
	row.add_child(lbl_val)
	parent.add_child(row)
