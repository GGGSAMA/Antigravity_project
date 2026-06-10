extends StaticBody3D

@export var facility_name: String = "一品灵田"
var is_growing: bool = false
var time_left: float = 0.0

var active_ui_panel: ColorRect = null

func interact(player: Node) -> void:
	if is_growing:
		if player.has_method("show_notification"):
			player.show_notification("【" + facility_name + "】灵草正在拼命生长（剩余 " + str(int(time_left)) + " 秒）")
		return
		
	_show_farm_ui(player)

func _show_farm_ui(player: Node) -> void:
	if active_ui_panel != null and is_instance_valid(active_ui_panel):
		return
		
	# 动态创建 UI 面板
	active_ui_panel = ColorRect.new()
	active_ui_panel.color = Color(0.1, 0.2, 0.1, 0.9) # 偏暗绿色的面板
	active_ui_panel.set_anchors_preset(Control.PRESET_CENTER)
	active_ui_panel.custom_minimum_size = Vector2(400, 300)
	
	var parent_node = player.get_node_or_null("HUD")
	if parent_node == null:
		parent_node = player.get_viewport()
	parent_node.add_child(active_ui_panel)
	
	active_ui_panel.position = (player.get_viewport().get_visible_rect().size - active_ui_panel.custom_minimum_size) / 2
	
	# 标题
	var title = Label.new()
	title.text = "【" + facility_name + "】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 20
	active_ui_panel.add_child(title)
	
	# 种植按钮
	var btn_plant = Button.new()
	btn_plant.text = "撒下种子：种植【聚灵草】"
	btn_plant.custom_minimum_size = Vector2(300, 50)
	btn_plant.set_anchors_preset(Control.PRESET_CENTER)
	btn_plant.position = (active_ui_panel.custom_minimum_size - btn_plant.custom_minimum_size) / 2
	btn_plant.pressed.connect(func(): _on_plant_pressed(player))
	active_ui_panel.add_child(btn_plant)
	
	# 关闭按钮
	var btn_close = Button.new()
	btn_close.text = "退出交互"
	btn_close.custom_minimum_size = Vector2(100, 40)
	btn_close.position = Vector2(150, 240)
	btn_close.pressed.connect(func(): _close_ui())
	active_ui_panel.add_child(btn_close)
	
	# 释放鼠标
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_plant_pressed(player: Node) -> void:
	if player.has_method("show_notification"):
		player.show_notification("刷... 种子落入泥土，开始汲取灵气！")
	
	is_growing = true
	time_left = 15.0 # 15秒成熟
	
	_close_ui()

func _close_ui() -> void:
	if active_ui_panel and is_instance_valid(active_ui_panel):
		active_ui_panel.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if is_growing:
		time_left -= delta
		if time_left <= 0:
			is_growing = false
			# 种植完成提示
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				if players[0].has_method("show_notification"):
					players[0].show_notification("叮！一株鲜嫩的【聚灵草】已成熟！")
