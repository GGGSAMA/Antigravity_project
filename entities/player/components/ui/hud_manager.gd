extends CanvasLayer
class_name HUDManager

@onready var notification_label: Label = $NotificationLabel
@onready var inventory_panel: ColorRect = $InventoryPanel
@onready var hotbar_panel: ColorRect = $HotbarPanel

# 全局拖拽状态 (跨组件共享)
var carried_item = null
var carried_icon: Label

# 悬浮提示 (Tooltip)
var tooltip_panel: PanelContainer
var tooltip_label: RichTextLabel

const ItemDatabase = preload("res://components/item_database.gd")

func _ready():
	UIStyles.init_styles()
	if notification_label:
		notification_label.modulate.a = 0
		
	# 建立全局鼠标拖拽图标
	carried_icon = Label.new()
	carried_icon.add_theme_font_size_override("font_size", 24)
	carried_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carried_icon.z_index = 100
	add_child(carried_icon)
	
	# 建立全局 Tooltip 面板
	tooltip_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.set_corner_radius_all(4)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.8, 0.6, 0.1, 0.5)
	tooltip_panel.add_theme_stylebox_override("panel", style)
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 99
	tooltip_panel.hide()
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tooltip_label.custom_minimum_size = Vector2(120, 10)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(tooltip_label)
	tooltip_panel.add_child(margin)
	add_child(tooltip_panel)

	# 动态构建并挂载全局 Dashboard 系统
	var DashboardScript = load("res://entities/player/components/ui/dashboard_ui.gd")
	if DashboardScript:
		var dashboard = DashboardScript.new()
		dashboard.name = "DashboardUI"
		dashboard.inventory_panel_ref = inventory_panel
		add_child(dashboard)
		# 强制将 Dashboard 插入到 hotbar_panel 之前，确保底部的快捷栏能够显示在界面上方
		if hotbar_panel:
			move_child(dashboard, hotbar_panel.get_index())
func _process(delta):
	# 更新拖拽图标和 Tooltip 的位置，使其跟随鼠标
	if carried_item:
		carried_icon.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)
		var meta = ItemDatabase.get_item(carried_item.id)
		carried_icon.text = meta.get("icon", "📦")
	else:
		carried_icon.text = ""
		
	if tooltip_panel.visible:
		tooltip_panel.global_position = get_viewport().get_mouse_position() + Vector2(15, 15)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var dashboard = get_node_or_null("DashboardUI")
		var is_open = dashboard != null and dashboard.visible
		
		# 按 ESC 关闭 UI
		if event.keycode == KEY_ESCAPE and is_open:
			toggle_panel(dashboard)
			get_viewport().set_input_as_handled()
			
		# 按 TAB 切换 UI
		elif event.keycode == KEY_TAB:
			if dashboard:
				toggle_panel(dashboard)
			else:
				toggle_panel(inventory_panel) # Fallback
			get_viewport().set_input_as_handled()

func toggle_panel(panel: Control):
	if panel:
		panel.visible = !panel.visible
		if panel.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# 丢弃手上的物品回到背包（防呆机制）
			if carried_item != null:
				owner.get("inventory_comp").add_item(carried_item.id, carried_item.qty)
				carried_item = null
				if inventory_panel and inventory_panel.has_method("update_ui"): inventory_panel.update_ui()
				if hotbar_panel and hotbar_panel.has_method("update_ui"): hotbar_panel.update_ui()

func show_notification(text: String):
	if notification_label:
		notification_label.text = text
		notification_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(notification_label, "modulate:a", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func show_tooltip(text: String):
	if text == "":
		tooltip_panel.hide()
	else:
		tooltip_label.text = text
		tooltip_panel.show()

func hide_tooltip():
	tooltip_panel.hide()
