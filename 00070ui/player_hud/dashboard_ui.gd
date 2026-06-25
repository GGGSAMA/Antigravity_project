extends "res://0000core/ui/base_menu_ui.gd"
class_name DashboardUI

var tab_container: TabContainer
var inventory_tab: MarginContainer
var stats_tab: MarginContainer
var skills_tab: MarginContainer

var inventory_panel_ref: Control
var stats_panel_script = preload("res://00070ui/player_hud/stats_panel.gd")
var skills_panel_script = preload("res://00070ui/player_hud/skills_panel.gd")

var bg: ColorRect

func _init():
	bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

func _ready():
	super._ready()
	z_index = 50 # Below NPCMonitor but above normal HUD
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 构建顶部导航系统 (TabContainer)
	tab_container = TabContainer.new()
	tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_container.add_theme_constant_override("side_margin", 20)

	# 自定义 Tab 样式
	var tab_bg = StyleBoxFlat.new()
	tab_bg.bg_color = Color(0, 0, 0, 0)
	var tab_fg = StyleBoxFlat.new()
	tab_fg.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	tab_fg.border_color = Color(0.8, 0.6, 0.1, 1.0)
	tab_fg.border_width_bottom = 2

	tab_container.add_theme_stylebox_override("panel", tab_bg)
	tab_container.add_theme_stylebox_override("tab_selected", tab_fg)

	# 1. 背包与装备页签
	inventory_tab = MarginContainer.new()
	inventory_tab.name = "包裹与法宝"
	inventory_tab.add_theme_constant_override("margin_top", 40)
	tab_container.add_child(inventory_tab)

	# 2. 人物属性页签
	stats_tab = MarginContainer.new()
	stats_tab.name = "修真境界"
	stats_tab.add_theme_constant_override("margin_top", 40)
	var stats_ui = stats_panel_script.new()
	stats_tab.add_child(stats_ui)
	tab_container.add_child(stats_tab)

	# 3. 功法技能页签
	skills_tab = MarginContainer.new()
	skills_tab.name = "神通功法"
	skills_tab.add_theme_constant_override("margin_top", 40)
	var skills_ui = skills_panel_script.new()
	skills_tab.add_child(skills_ui)
	tab_container.add_child(skills_tab)

	bg.add_child(tab_container)

	# 尝试将旧的 InventoryPanel 吸收入包裹页签
	call_deferred("_reparent_inventory_panel")

func _reparent_inventory_panel():
	if inventory_panel_ref and inventory_panel_ref.get_parent():
		inventory_panel_ref.get_parent().remove_child(inventory_panel_ref)
		inventory_tab.add_child(inventory_panel_ref)
		# 修正原本 InventoryUI 的锚点和显示逻辑
		inventory_panel_ref.custom_minimum_size = Vector2(520, 450)
		inventory_panel_ref.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inventory_panel_ref.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inventory_panel_ref.set_anchors_preset(Control.PRESET_CENTER)
		inventory_panel_ref.visible = true # 在 Tab 里面永远为 true，由 Dashboard 统筹可见性
		
		var old_tabs = inventory_panel_ref.get_node_or_null("TopTabs")
		if old_tabs:
			old_tabs.queue_free()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_inventory") and not event.is_echo():
		close_ui()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	pass

func update_all():
	if inventory_panel_ref and inventory_panel_ref.has_method("update_ui"):
		inventory_panel_ref.update_ui()
	# TODO: 更新 Stats 和 Skills

func cycle_tab() -> void:
	if tab_container:
		var total_tabs = tab_container.get_tab_count()
		if total_tabs > 0:
			tab_container.current_tab = (tab_container.current_tab + 1) % total_tabs
