extends ColorRect
class_name DashboardUI

var tab_container: TabContainer
var inventory_tab: MarginContainer
var stats_tab: MarginContainer
var skills_tab: MarginContainer

var inventory_panel_ref: Control
var stats_panel_script = preload("res://entities/player/components/ui/stats_panel.gd")
var skills_panel_script = preload("res://entities/player/components/ui/skills_panel.gd")

func _init():
	# 全屏虚化背景设置
	color = Color(0.02, 0.02, 0.03, 0.85)
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func _ready():
	# 构建顶部导航系统 (TabContainer)
	tab_container = TabContainer.new()
	tab_container.set_anchors_preset(PRESET_FULL_RECT)
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
	
	add_child(tab_container)

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
		inventory_panel_ref.set_anchors_preset(PRESET_CENTER)
		inventory_panel_ref.visible = true # 在 Tab 里面永远为 true，由 Dashboard 统筹可见性

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[DEBUG DashboardUI] _gui_input 拦截了鼠标点击！位置: ", event.position)

func update_all():
	if inventory_panel_ref and inventory_panel_ref.has_method("update_ui"):
		inventory_panel_ref.update_ui()
	# TODO: 更新 Stats 和 Skills

func cycle_tab() -> void:
	if tab_container:
		var total_tabs = tab_container.get_tab_count()
		if total_tabs > 0:
			tab_container.current_tab = (tab_container.current_tab + 1) % total_tabs
