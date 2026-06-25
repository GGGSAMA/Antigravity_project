extends ColorRect
class_name DreamerUI

const STATE_SELECT_OWN = 0
const STATE_OPEN_OTHERS = 1
const STATE_OFFER = 2
const STATE_GAME_OVER = 3

var state = STATE_SELECT_OWN
var base_prizes = [1, 5, 10, 50, 100, 300, 800, 2000, 5000, 10000]
var chest_contents = [] # 10 elements matching base_prizes shuffled
var opened_indices = []
var player_chest_idx = -1
var chests_to_open = 0
var current_offer = 0

# UI Refs
var prize_labels = []
var chest_btns = []
var own_chest_btn: Button
var host_label: RichTextLabel
var deal_btn: Button
var no_deal_btn: Button
var cancel_btn: Button
var own_chest_rtl: RichTextLabel

func _ready() -> void:
	hide()
	color = Color(0.02, 0.05, 0.1, 0.95)
	anchors_preset = 15
	anchor_right = 1.0
	anchor_bottom = 1.0

	_build_ui()

func start_game():
	print("[DreamerUI] 启动太虚幻境！")
	chest_contents = base_prizes.duplicate()
	chest_contents.shuffle()

	opened_indices.clear()
	player_chest_idx = -1
	current_offer = 0

	_refresh_prize_board()
	_reset_chest_buttons()

	deal_btn.hide()
	no_deal_btn.hide()
	cancel_btn.hide()
	own_chest_rtl.text = "[center]你的宝箱\n[未选择][/center]"
	own_chest_btn.disabled = true

	_set_state(STATE_SELECT_OWN)
	show()

func close_game():
	hide()
	# 把鼠标交还给 HUDManager 管理
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("_update_mouse_state"):
			hud._update_mouse_state()

func _set_state(s: int):
	state = s
	match state:
		STATE_SELECT_OWN:
			host_label.text = "【幻境主宰】欢迎来到太虚赌局！\n请从 10 个盲盒中，挑选 1 个作为你的[color=yellow]【本命宝箱】[/color]。"
		STATE_OPEN_OTHERS:
			if chests_to_open > 0:
				host_label.text = "【幻境主宰】请再开启 " + str(chests_to_open) + " 个宝箱，排除那些垃圾奖励！"
			else:
				_trigger_offer()
		STATE_OFFER:
			host_label.text = "【幻境主宰】我的报价是：[color=yellow]" + str(current_offer) + " 灵石[/color]。\n你选择成交(Deal)，还是继续(No Deal)？"
			deal_btn.show()
			no_deal_btn.show()
		STATE_GAME_OVER:
			cancel_btn.show()
			deal_btn.hide()
			no_deal_btn.hide()

func _trigger_offer():
	var sum = 0.0
	var count = 0
	for i in range(10):
		if i != player_chest_idx and not opened_indices.has(i):
			sum += chest_contents[i]
			count += 1

	if count == 0:
		# 仅剩自己的宝箱了！
		_final_reveal()
		return

	# 包含自己的宝箱算总平均
	sum += chest_contents[player_chest_idx]
	count += 1

	var avg = sum / count
	# 庄家报价会有一定随机扰动 (0.85 ~ 1.05倍)
	current_offer = int(avg * randf_range(0.85, 1.05))

	_set_state(STATE_OFFER)

func _final_reveal():
	var win_amount = chest_contents[player_chest_idx]
	own_chest_rtl.text = "[center]你的宝箱\n[color=yellow]" + str(win_amount) + "[/color][/center]"
	host_label.text = "【幻境主宰】刺激！你的本命宝箱里居然是... [color=yellow]" + str(win_amount) + " 灵石[/color]！拿走吧！"
	_give_player_money(win_amount)
	_set_state(STATE_GAME_OVER)

func _give_player_money(amount: int):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
		if stats:
			stats.spirit_stones += amount
			print("[DreamerUI] 玩家赢得 ", amount, " 灵石！")
			var hud = player.get_node_or_null("HUD")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("赢得 " + str(amount) + " 灵石！")

func _on_chest_click(idx: int):
	if state == STATE_SELECT_OWN:
		player_chest_idx = idx
		chest_btns[idx].visible = false
		own_chest_rtl.text = "[center]你的宝箱\n[已选定][/center]"
		chests_to_open = 2
		_set_state(STATE_OPEN_OTHERS)

	elif state == STATE_OPEN_OTHERS:
		if idx == player_chest_idx or opened_indices.has(idx): return
		opened_indices.append(idx)

		var val = chest_contents[idx]
		chest_btns[idx].text = str(val)
		chest_btns[idx].disabled = true
		# 让按钮变灰
		chest_btns[idx].add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

		_mark_prize_opened(val)

		chests_to_open -= 1
		if chests_to_open <= 0:
			_set_state(STATE_OPEN_OTHERS) # Will trigger offer next
		else:
			host_label.text = "【幻境主宰】哦？排除了 " + str(val) + "。还需开启 " + str(chests_to_open) + " 个。"

func _on_deal_pressed():
	host_label.text = "【幻境主宰】明智的选择！拿着你的 [color=yellow]" + str(current_offer) + " 灵石[/color] 离开吧！\n顺便看看你原本会拿到什么？"
	var win_amount = chest_contents[player_chest_idx]
	own_chest_rtl.text = "[center]你的宝箱\n(错过)[color=gray]" + str(win_amount) + "[/color][/center]"
	_give_player_money(current_offer)
	_set_state(STATE_GAME_OVER)

func _on_no_deal_pressed():
	deal_btn.hide()
	no_deal_btn.hide()

	# 计算剩余未开箱子（不含自己的）
	var rem = 10 - opened_indices.size() - 1
	if rem > 2:
		chests_to_open = 2
	else:
		chests_to_open = 1

	_set_state(STATE_OPEN_OTHERS)

func _mark_prize_opened(val: int):
	for lbl in prize_labels:
		if lbl.get_meta("val") == val and not lbl.get_meta("opened", false):
			lbl.set_meta("opened", true)
			lbl.text = "[s][color=gray]" + str(val) + "[/color][/s]"
			break

func _refresh_prize_board():
	for i in range(10):
		var lbl = prize_labels[i]
		var val = base_prizes[i]
		lbl.set_meta("val", val)
		lbl.set_meta("opened", false)

		# 颜色分级
		if val >= 2000: lbl.text = "[color=orange]" + str(val) + "[/color]"
		elif val >= 300: lbl.text = "[color=yellow]" + str(val) + "[/color]"
		else: lbl.text = "[color=white]" + str(val) + "[/color]"

func _reset_chest_buttons():
	for i in range(10):
		chest_btns[i].text = "?"
		chest_btns[i].disabled = false
		chest_btns[i].visible = true
		chest_btns[i].remove_theme_color_override("font_disabled_color")

func _build_ui():
	var main_hbox = HBoxContainer.new()
	main_hbox.anchors_preset = 15; main_hbox.anchor_right = 1.0; main_hbox.anchor_bottom = 1.0
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 50)
	add_child(main_hbox)

	# Left: Prize Board
	var prize_pnl = PanelContainer.new()
	prize_pnl.custom_minimum_size = Vector2(200, 500)
	var style1 = StyleBoxFlat.new(); style1.bg_color = Color(0.1, 0.1, 0.15, 0.9); prize_pnl.add_theme_stylebox_override("panel", style1)
	main_hbox.add_child(prize_pnl)

	var prize_v = VBoxContainer.new()
	prize_pnl.add_child(prize_v)
	var plbl = Label.new(); plbl.text = "可能金额"; plbl.horizontal_alignment = 1; plbl.add_theme_font_size_override("font_size", 24)
	prize_v.add_child(plbl)

	for i in range(10):
		var lbl = RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.custom_minimum_size = Vector2(180, 30)
		lbl.add_theme_font_size_override("normal_font_size", 20)
		prize_v.add_child(lbl)
		prize_labels.append(lbl)

	# Right: Game Board
	var game_v = VBoxContainer.new()
	game_v.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(game_v)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	game_v.add_child(grid)

	for i in range(10):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.add_theme_font_size_override("font_size", 32)
		btn.pressed.connect(_on_chest_click.bind(i))
		grid.add_child(btn)
		chest_btns.append(btn)

	# Space
	var spacer = Control.new(); spacer.custom_minimum_size = Vector2(0, 50); game_v.add_child(spacer)

	# Own Chest
	var own_hbox = HBoxContainer.new()
	own_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_v.add_child(own_hbox)

	own_chest_btn = Button.new()
	own_chest_btn.custom_minimum_size = Vector2(180, 100)
	own_chest_btn.disabled = true
	var own_style = StyleBoxFlat.new(); own_style.bg_color = Color(0.6, 0.4, 0.1, 0.8)
	own_chest_btn.add_theme_stylebox_override("disabled", own_style)

	own_chest_rtl = RichTextLabel.new()
	own_chest_rtl.bbcode_enabled = true
	own_chest_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	own_chest_rtl.anchors_preset = 15; own_chest_rtl.anchor_right = 1.0; own_chest_rtl.anchor_bottom = 1.0
	own_chest_rtl.add_theme_font_size_override("normal_font_size", 20)
	own_chest_btn.add_child(own_chest_rtl)

	own_hbox.add_child(own_chest_btn)

	# Space
	var spacer2 = Control.new(); spacer2.custom_minimum_size = Vector2(0, 30); game_v.add_child(spacer2)

	# Host Dialogue
	var host_pnl = PanelContainer.new()
	host_pnl.custom_minimum_size = Vector2(600, 150)
	var hstyle = StyleBoxFlat.new(); hstyle.bg_color = Color(0.05, 0.1, 0.05, 0.9)
	hstyle.border_color = Color(0.2, 0.6, 0.2); hstyle.border_width_left = 2; hstyle.border_width_top = 2
	hstyle.border_width_right = 2; hstyle.border_width_bottom = 2
	host_pnl.add_theme_stylebox_override("panel", hstyle)
	game_v.add_child(host_pnl)

	var host_v = VBoxContainer.new()
	host_pnl.add_child(host_v)

	host_label = RichTextLabel.new()
	host_label.bbcode_enabled = true
	host_label.fit_content = true
	host_label.custom_minimum_size = Vector2(580, 80)
	host_label.add_theme_font_size_override("normal_font_size", 22)
	host_v.add_child(host_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	host_v.add_child(btn_hbox)

	deal_btn = Button.new(); deal_btn.text = " 成 交 (DEAL) "
	deal_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	deal_btn.custom_minimum_size = Vector2(150, 40)
	deal_btn.pressed.connect(_on_deal_pressed)
	btn_hbox.add_child(deal_btn)

	no_deal_btn = Button.new(); no_deal_btn.text = " 继 续 (NO DEAL) "
	no_deal_btn.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	no_deal_btn.custom_minimum_size = Vector2(150, 40)
	no_deal_btn.pressed.connect(_on_no_deal_pressed)
	btn_hbox.add_child(no_deal_btn)

	cancel_btn = Button.new(); cancel_btn.text = " 离 开 "
	cancel_btn.custom_minimum_size = Vector2(100, 40)
	cancel_btn.pressed.connect(close_game)
	btn_hbox.add_child(cancel_btn)
