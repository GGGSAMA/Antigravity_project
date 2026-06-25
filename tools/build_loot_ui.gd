extends SceneTree

func _init():
	var root = ColorRect.new()
	root.name = "LootContainerUI"
	root.color = Color(0, 0, 0, 0.8)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://00070ui/player_hud/loot_container_ui.gd"))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(hbox)
	hbox.owner = root
	
	var player_panel = VBoxContainer.new()
	player_panel.name = "PlayerPanel"
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(player_panel)
	player_panel.owner = root
	
	var lbl1 = Label.new()
	lbl1.text = "玩家背包"
	lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(lbl1)
	lbl1.owner = root
	
	var p_scroll = ScrollContainer.new()
	p_scroll.name = "Scroll"
	p_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_panel.add_child(p_scroll)
	p_scroll.owner = root
	
	var p_grid = GridContainer.new()
	p_grid.name = "PlayerGrid"
	p_grid.columns = 6
	p_scroll.add_child(p_grid)
	p_grid.owner = root
	
	var container_panel = VBoxContainer.new()
	container_panel.name = "ContainerPanel"
	container_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(container_panel)
	container_panel.owner = root
	
	var header = HBoxContainer.new()
	header.name = "Header"
	container_panel.add_child(header)
	header.owner = root
	
	var lbl2 = Label.new()
	lbl2.text = "搜刮容器"
	lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl2)
	lbl2.owner = root
	
	var btn_take_all = Button.new()
	btn_take_all.name = "BtnTakeAll"
	btn_take_all.text = "全部拿走 (Take All)"
	header.add_child(btn_take_all)
	btn_take_all.owner = root
	
	var btn_close = Button.new()
	btn_close.name = "BtnClose"
	btn_close.text = "X"
	header.add_child(btn_close)
	btn_close.owner = root
	
	var c_scroll = ScrollContainer.new()
	c_scroll.name = "Scroll"
	c_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container_panel.add_child(c_scroll)
	c_scroll.owner = root
	
	var c_grid = GridContainer.new()
	c_grid.name = "ContainerGrid"
	c_grid.columns = 6
	c_scroll.add_child(c_grid)
	c_grid.owner = root
	
	var pack = PackedScene.new()
	pack.pack(root)
	ResourceSaver.save(pack, "res://00070ui/player_hud/loot_container_ui.tscn")
	print("Saved loot_container_ui.tscn")
	quit()
