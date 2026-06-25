extends "res://0000core/ui/base_menu_ui.gd"
class_name TradeUI

var player_comp
var npc_data: CharacterData

# UI Refs
var player_grid: GridContainer
var npc_grid: GridContainer
var staging_sell_grid: GridContainer
var staging_buy_grid: GridContainer
var diff_label: Label
var confirm_btn: Button

# Staged Items logic (what is moved to center)
var staged_sell = [] # items player gives
var staged_buy = [] # items npc gives
var player_money_ref
var npc_money_ref

const ItemDatabase = preload("res://0000core/data/item_database.gd")

func _ready():
	super._ready()
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.06, 0.95)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	anchors_preset = Control.PRESET_FULL_RECT

	_build_ui()

func open_trade(npc: CharacterData):
	open_ui()
	npc_data = npc
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_comp = player.get("inventory_comp")

	staged_sell.clear()
	staged_buy.clear()

	_refresh_all()

func close_trade():
	close_ui()
	staged_sell.clear()
	staged_buy.clear()
	staged_buy.clear()

func _build_ui():
	# Main container
	var main_hbox = HBoxContainer.new()
	main_hbox.anchors_preset = 15
	main_hbox.anchor_right = 1.0
	main_hbox.anchor_bottom = 1.0
	main_hbox.add_theme_constant_override("separation", 20)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_hbox)

	# Left: Player
	var left_panel = _build_side_panel("我方", true)
	player_grid = left_panel.get_node("VBox/Scroll/Grid")
	player_money_ref = left_panel.get_node("VBox/MoneyLabel")
	main_hbox.add_child(left_panel)

	# Middle: Staging
	var center_panel = _build_staging_panel()
	main_hbox.add_child(center_panel)

	# Right: NPC
	var right_panel = _build_side_panel("对方", false)
	npc_grid = right_panel.get_node("VBox/Scroll/Grid")
	npc_money_ref = right_panel.get_node("VBox/MoneyLabel")
	main_hbox.add_child(right_panel)

func _build_side_panel(title_text: String, is_player: bool) -> PanelContainer:
	var pnl = PanelContainer.new()
	pnl.custom_minimum_size = Vector2(350, 600)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(0.6, 0.4, 0.1, 1)
	style.border_width_left = 4; style.border_width_right = 4; style.border_width_top = 4; style.border_width_bottom = 4
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	pnl.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	pnl.add_child(vbox)

	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = 1
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "Grid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	var money = Label.new()
	money.name = "MoneyLabel"
	money.text = "灵石: 0"
	money.horizontal_alignment = 1
	money.add_theme_color_override("font_color", Color(0.5, 0.9, 0.9))
	vbox.add_child(money)

	return pnl

func _build_staging_panel() -> PanelContainer:
	var pnl = PanelContainer.new()
	pnl.custom_minimum_size = Vector2(400, 600)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.15, 0.95)
	style.border_color = Color(0.2, 0.5, 0.6, 1)
	style.border_width_left = 4; style.border_width_right = 4; style.border_width_top = 4; style.border_width_bottom = 4
	pnl.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	pnl.add_child(vbox)

	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	var sell_scroll = ScrollContainer.new()
	sell_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sell_v = VBoxContainer.new(); sell_scroll.add_child(sell_v)
	var slbl = Label.new(); slbl.text = "出售区"; slbl.horizontal_alignment = 1; sell_v.add_child(slbl)
	staging_sell_grid = GridContainer.new(); staging_sell_grid.columns = 2; sell_v.add_child(staging_sell_grid)
	hbox.add_child(sell_scroll)

	var buy_scroll = ScrollContainer.new()
	buy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var buy_v = VBoxContainer.new(); buy_scroll.add_child(buy_v)
	var blbl = Label.new(); blbl.text = "收购区"; blbl.horizontal_alignment = 1; buy_v.add_child(blbl)
	staging_buy_grid = GridContainer.new(); staging_buy_grid.columns = 2; buy_v.add_child(staging_buy_grid)
	hbox.add_child(buy_scroll)

	diff_label = Label.new()
	diff_label.text = "差价: 0"
	diff_label.horizontal_alignment = 1
	vbox.add_child(diff_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var cancel = Button.new()
	cancel.text = " 返 回 "
	cancel.pressed.connect(close_trade)
	btn_hbox.add_child(cancel)

	confirm_btn = Button.new()
	confirm_btn.text = " 确 定 "
	confirm_btn.pressed.connect(_on_confirm)
	btn_hbox.add_child(confirm_btn)

	return pnl

func _create_item_btn(item_id: String, qty: int, is_player: bool, is_staged: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(70, 70)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.1, 0.9)
	style.border_color = Color(0.4, 0.3, 0.2)
	style.border_width_left = 2; style.border_width_top = 2; style.border_width_right = 2; style.border_width_bottom = 2
	style.corner_radius_top_left = 6; style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)

	var meta = ItemDatabase.get_item(item_id)

	var icon = Label.new()
	icon.text = meta.icon
	icon.anchors_preset = 15; icon.anchor_right = 1.0; icon.anchor_bottom = 1.0
	icon.horizontal_alignment = 1; icon.vertical_alignment = 1
	icon.add_theme_font_size_override("font_size", 30)
	btn.add_child(icon)

	var qlbl = Label.new()
	qlbl.text = str(qty)
	qlbl.anchors_preset = 3; qlbl.anchor_left = 1.0; qlbl.anchor_top = 1.0; qlbl.anchor_right = 1.0; qlbl.anchor_bottom = 1.0
	qlbl.horizontal_alignment = 2; qlbl.vertical_alignment = 2
	btn.add_child(qlbl)

	btn.pressed.connect(_on_item_click.bind(item_id, qty, is_player, is_staged))
	return btn

func _refresh_all():
	for c in player_grid.get_children(): c.queue_free()
	for c in npc_grid.get_children(): c.queue_free()
	for c in staging_sell_grid.get_children(): c.queue_free()
	for c in staging_buy_grid.get_children(): c.queue_free()

	var p_money = 0
	if player_comp and player_comp.get_parent().get("stats") != null:
		p_money = player_comp.get_parent().stats.spirit_stones
	player_money_ref.text = "灵石: " + str(p_money)

	var n_money = npc_data.money if npc_data else 0
	npc_money_ref.text = "灵石: " + str(n_money)

	# Player inventory
	if player_comp:
		var p_inv = {} 
		for slot in player_comp.slots:
			if slot:
				p_inv[slot.get_item_id()] = p_inv.get(slot.get_item_id(), 0) + slot.qty

		for sid in staged_sell:
			if p_inv.has(sid): p_inv[sid] -= 1

		for id in p_inv:
			if p_inv[id] > 0:
				player_grid.add_child(_create_item_btn(id, p_inv[id], true, false))

	# NPC inventory
	if npc_data and npc_data.inventory:
		var n_inv = npc_data.inventory.duplicate()
		for sid in staged_buy:
			if n_inv.has(sid): n_inv[sid] -= 1

		for id in n_inv:
			if n_inv[id] > 0:
				npc_grid.add_child(_create_item_btn(id, n_inv[id], false, false))

	# Staged
	var s_sell_dict = {}
	for id in staged_sell: s_sell_dict[id] = s_sell_dict.get(id, 0) + 1
	for id in s_sell_dict: staging_sell_grid.add_child(_create_item_btn(id, s_sell_dict[id], true, true))

	var s_buy_dict = {}
	for id in staged_buy: s_buy_dict[id] = s_buy_dict.get(id, 0) + 1
	for id in s_buy_dict: staging_buy_grid.add_child(_create_item_btn(id, s_buy_dict[id], false, true))

	_recalc_diff()

func _on_item_click(item_id: String, qty: int, is_player: bool, is_staged: bool):
	if is_staged:
		if is_player: staged_sell.erase(item_id)
		else: staged_buy.erase(item_id)
	else:
		if is_player: staged_sell.append(item_id)
		else: staged_buy.append(item_id)
	_refresh_all()

func _recalc_diff():
	var diff = 0
	for id in staged_sell: diff += ItemDatabase.get_item(id).price
	for id in staged_buy: diff -= ItemDatabase.get_item(id).price

	diff_label.text = "结算差额: " + str(diff) + " 灵石"
	if diff > 0: diff_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	elif diff < 0: diff_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	else: diff_label.add_theme_color_override("font_color", Color(1,1,1))

func _on_confirm():
	var diff = 0
	for id in staged_sell: diff += ItemDatabase.get_item(id).price
	for id in staged_buy: diff -= ItemDatabase.get_item(id).price

	var player = player_comp.get_parent()
	var p_stats = player.get("stats")
	if p_stats == null:
		print("玩家属性异常，无法交易！")
		return

	if diff < 0 and p_stats.spirit_stones < abs(diff):
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("灵石不足！")
		return
	if diff > 0 and npc_data.money < diff:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("对方灵石不足！")
		return

	# Execute
	p_stats.spirit_stones += diff
	npc_data.money -= diff

	for id in staged_sell:
		player_comp.remove_item(id, 1)
		npc_data.inventory[id] = npc_data.inventory.get(id, 0) + 1

	for id in staged_buy:
		npc_data.inventory[id] -= 1
		player_comp.add_item(id, 1)

	staged_sell.clear()
	staged_buy.clear()
	_refresh_all()
	print("交易成功！")
