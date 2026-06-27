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

const ItemDatabase = preload("res://0000core/000040_data/item_database.gd")

func _ready():
	UIStyles.init_styles()
	if notification_label:
		notification_label.modulate.a = 0
		
	# Connect to CombatComponent notification seam
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("CombatComponent"):
		var combat = player.get_node("CombatComponent")
		if combat.has_signal("notification_requested"):
			combat.notification_requested.connect(show_notification)
			
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.request_open_ui.connect(_on_request_open_ui)
		event_bus.show_notification.connect(show_notification)
		
	# 建立全局鼠标拖拽图标
	carried_icon = Label.new()
	carried_icon.add_theme_font_size_override("font_size", 24)
	carried_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carried_icon.z_index = 100
	add_child(carried_icon)
	
	# 建立全局 Tooltip 面板
	tooltip_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.15, 0.18, 0.95) # Deep teal
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.8, 0.6, 0.8) # Jade border
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 4
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
	var DashboardScript = load("res://00070ui/player_hud/dashboard_ui.gd")
	if DashboardScript:
		var dashboard = DashboardScript.new()
		dashboard.name = "DashboardUI"
		dashboard.inventory_panel_ref = inventory_panel
		add_child(dashboard)
		# 强制将 Dashboard 插入到 hotbar_panel 之前，确保底部的快捷栏能够显示在界面上方
		if hotbar_panel:
			move_child(dashboard, hotbar_panel.get_index())
			
	var ScannerHUDScript = load("res://00070ui/player_hud/scanner_hud.gd")
	if ScannerHUDScript:
		var scanner_hud = ScannerHUDScript.new()
		scanner_hud.name = "ScannerHUD"
		add_child(scanner_hud)
		# 延迟绑定 ScannerComponent
		call_deferred("_bind_scanner_hud", scanner_hud)
			
	var meditation = get_node_or_null("MeditationUI")
	if meditation:
		meditation.set_player_stats(owner.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr"))
		
	var spell_wheel = get_node_or_null("SpellWheelUI")
	if spell_wheel:
		spell_wheel.spell_selected.connect(_on_spell_selected)
		
	var TradeUIScript = load("res://00070ui/player_hud/trade_ui.gd")
	if TradeUIScript:
		var trade_ui = TradeUIScript.new()
		trade_ui.name = "TradeUI"
		add_child(trade_ui)

	# F4 调试面板 - NPC全属性与天道播报
	var NPCMonitorScript = load("res://00070ui/debug/npc_monitor.gd")
	if NPCMonitorScript:
		var npc_monitor = NPCMonitorScript.new()
		npc_monitor.name = "NPCMonitorUI"
		add_child(npc_monitor)

func _bind_scanner_hud(scanner_hud: Node) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var scanner_comp = player.get_node_or_null("ScannerComponent")
		if scanner_comp:
			scanner_hud.setup_scanner(scanner_comp)

func _on_spell_selected(spell_id: String) -> void:
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
		var meta = ItemDatabase.get_item(carried_item.get_item_id())
		carried_icon.text = meta.icon
	else:
		carried_icon.text = ""
		
	if tooltip_panel.visible:
		tooltip_panel.global_position = get_viewport().get_mouse_position() + Vector2(15, 15)

func _on_request_open_ui(ui_name: String) -> void:
	if ui_name == "action_menu":
		var action_menu = get_node_or_null("ActionMenuUI")
		if action_menu:
			if action_menu.visible:
				if action_menu.has_method("close_ui"): action_menu.close_ui()
				elif action_menu.has_method("hide_ui"): action_menu.hide_ui()
				if tooltip_panel: tooltip_panel.hide()
			else:
				if action_menu.has_method("open_ui"): action_menu.open_ui()
				elif action_menu.has_method("show_ui"): action_menu.show_ui()
	elif ui_name == "inventory":
		var dashboard = get_node_or_null("DashboardUI")
		if dashboard:
			if dashboard.visible:
				dashboard.close_ui()
				if tooltip_panel: tooltip_panel.hide()
				if carried_item != null:
					var player = get_tree().get_first_node_in_group("player")
					if player and player.get("inventory_comp"):
						player.get("inventory_comp").add_item(carried_item.get_item_id(), carried_item.qty)
					carried_item = null
					carried_icon.text = ""
			else:
				dashboard.open_ui()
	elif ui_name == "debug_monitor":
		var npc_monitor = get_node_or_null("NPCMonitorUI")
		if npc_monitor:
			npc_monitor.toggle()
	elif ui_name == "meditation":
		var meditation = get_node_or_null("MeditationUI")
		if meditation:
			if meditation.visible:
				if meditation.has_method("close_ui"): meditation.close_ui()
			else:
				if meditation.has_method("open_ui"): meditation.open_ui()

func _input(event: InputEvent) -> void:
	# 按住 Q 呼出法术轮盘 (按住类特殊交互，暂保留在底层)
	if event.is_action("ui_spell_wheel"):
		var spell_wheel = get_node_or_null("SpellWheelUI")
		if spell_wheel:
			if event.is_pressed() and not event.is_echo():
				spell_wheel.open_wheel()
			elif not event.is_pressed():
				spell_wheel.close_wheel()
		get_viewport().set_input_as_handled()

# _update_mouse_state() 已被移除，改为通过 UIStackManager 自动更新

func toggle_panel(panel: Control):
	if panel:
		if panel.has_method("toggle"):
			panel.toggle()
		else:
			panel.visible = !panel.visible
			# 丢弃手上的物品回到背包（防呆机制）
			if carried_item != null:
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.get("inventory_comp").add_item(carried_item.get_item_id(), carried_item.qty)
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

func open_loot_container(loot_comp: Node) -> void:
	var loot_ui = get_node_or_null("LootContainerUI")
	if not loot_ui:
		var scene = load("res://00070ui/player_hud/loot_container_ui.tscn")
		if scene:
			loot_ui = scene.instantiate()
			loot_ui.name = "LootContainerUI"
			add_child(loot_ui)
			# Insert before tooltip
			move_child(loot_ui, tooltip_panel.get_index())
			
	if loot_ui:
		var player = get_tree().get_first_node_in_group("player")
		var inv = player.get("inventory_comp") if player else null
		loot_ui.setup(inv, loot_comp, self)
		loot_ui.show()
		
		# Set focus to capture mouse mode appropriately via UIFocusManager if it exists
		if UIFocusManager:
			UIFocusManager.push_ui(loot_ui)
