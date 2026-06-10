extends Control

func _init():
	set_anchors_preset(PRESET_FULL_RECT)

func _ready():
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	
	var title = Label.new()
	title.text = "【神通功法】\n目前尚未领悟任何绝学"
	title.horizontal_alignment = 1
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "（日后可在此处将法术拖拽至底部快捷栏绑定）"
	desc.horizontal_alignment = 1
	desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(desc)
	
	add_child(vbox)
