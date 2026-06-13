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
			
	var ScannerHUDScript = load("res://entities/player/components/ui/scanner_hud.gd")
	if ScannerHUDScript:
		var scanner_hud = ScannerHUDScript.new()
		scanner_hud.name = "ScannerHUD"
		add_child(scanner_hud)
		# 延迟绑定 ScannerComponent
		call_deferred("_bind_scanner_hud", scanner_hud)
			
	var meditation = get_node_or_null("MeditationUI")
	if meditation:
		meditation.set_player_stats(owner.get_node_or_null("Stats"))
		
	var spell_wheel = get_node_or_null("SpellWheelUI")
	if spell_wheel:
		spell_wheel.spell_selected.connect(_on_spell_selected)

func _bind_scanner_hud(scanner_hud: Node) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var scanner_comp = player.get_node_or_null("ScannerComponent")
		if scanner_comp:
			scanner_hud.setup_scanner(scanner_comp)

func _on_spell_selected(spell_id: String) -> void:
	if spell_id == "": return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var spell_comp = player.get("spells")
	if not spell_comp: return
	
	var spell_wheel = get_node_or_null("SpellWheelUI")
	var is_left = false
	if spell_wheel:
		is_left = spell_wheel.get("is_left_hand")
		
	if spell_comp.has_method("set_active_spell_id"):
		spell_comp.set_active_spell_id(is_left, spell_id)

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
	if event is InputEventKey:
		var dashboard = get_node_or_null("DashboardUI")
		var is_dashboard_open = dashboard != null and dashboard.visible
		var action_menu = get_node_or_null("ActionMenuUI")
		var is_action_menu_open = action_menu != null and action_menu.visible
		var meditation = get_node_or_null("MeditationUI")
		var is_meditation_open = meditation != null and meditation.visible
		
		var any_ui_open = is_dashboard_open or is_action_menu_open or is_meditation_open
		
		# 按 ESC 关闭当前所有激活的 UI
		if event.is_action_pressed("ui_cancel") and any_ui_open:
			if is_dashboard_open: 
				dashboard.hide()
			if is_action_menu_open: action_menu.hide_ui()
			if is_meditation_open: meditation.hide_ui()
			
			_update_mouse_state()
			
			# 丢弃手上的物品回到背包（防呆机制）
			if carried_item != null:
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.get("inventory_comp").add_item(carried_item.id, carried_item.qty)
				carried_item = null
				if inventory_panel and inventory_panel.has_method("update_ui"): inventory_panel.update_ui()
				if hotbar_panel and hotbar_panel.has_method("update_ui"): hotbar_panel.update_ui()
				
			get_viewport().set_input_as_handled()
			
		# 按 TAB 逻辑
		elif event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
			if not is_dashboard_open:
				if dashboard:
					dashboard.show()
					_update_mouse_state()
			else:
				if dashboard and dashboard.has_method("cycle_tab"):
					dashboard.cycle_tab()
			get_viewport().set_input_as_handled()
			
		# 按 E 呼出/关闭 行为菜单
		elif event.keycode == KEY_E and event.pressed:
			if action_menu:
				if action_menu.visible:
					action_menu.hide_ui()
				else:
					action_menu.show_ui()
				_update_mouse_state()
			get_viewport().set_input_as_handled()
				
		# 按住 Q 呼出法术轮盘
		elif event.keycode == KEY_Q:
			var spell_wheel = get_node_or_null("SpellWheelUI")
			if spell_wheel:
				if event.pressed and not event.is_echo():
					spell_wheel.open_wheel()
					_update_mouse_state()
				elif not event.pressed:
					spell_wheel.close_wheel()
					_update_mouse_state()
			get_viewport().set_input_as_handled()

func _update_mouse_state() -> void:
	var dashboard = get_node_or_null("DashboardUI")
	var action_menu = get_node_or_null("ActionMenuUI")
	var meditation = get_node_or_null("MeditationUI")
	var spell_wheel = get_node_or_null("SpellWheelUI")
	
	var is_ui_open = (dashboard and dashboard.visible) or \
					 (action_menu and action_menu.visible) or \
					 (meditation and meditation.visible) or \
					 (spell_wheel and spell_wheel.get("is_open"))
					 
	if is_ui_open:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE and Input.mouse_mode != Input.MOUSE_MODE_CONFINED_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_panel(panel: Control):
	if panel:
		panel.visible = !panel.visible
		_update_mouse_state()
		if not panel.visible:
			# 丢弃手上的物品回到背包（防呆机制）
			if carried_item != null:
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.get("inventory_comp").add_item(carried_item.id, carried_item.qty)
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
