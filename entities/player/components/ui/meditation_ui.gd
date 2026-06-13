extends Control
class_name MeditationUI

@onready var mode_option = $Panel/VBoxContainer/ModeHBox/ModeOption
@onready var spell_hbox = $Panel/VBoxContainer/SpellHBox
@onready var spell_option = $Panel/VBoxContainer/SpellHBox/SpellOption
@onready var year_slider = $Panel/VBoxContainer/YearSlider
@onready var year_label = $Panel/VBoxContainer/HBoxContainer/YearLabel
@onready var start_btn = $Panel/VBoxContainer/StartButton
@onready var stop_btn = $Panel/VBoxContainer/StopButton
@onready var close_btn = $Panel/VBoxContainer/CloseButton
@onready var log_label = $Panel/VBoxContainer/LogLabel

var player_stats: Node
var is_meditating: bool = false
const SpellDatabase = preload("res://components/spell_database.gd")

func _ready() -> void:
	visible = false
	
	year_slider.value_changed.connect(_on_slider_changed)
	start_btn.pressed.connect(_on_start_pressed)
	stop_btn.pressed.connect(_on_stop_pressed)
	close_btn.pressed.connect(hide_ui)
	
	mode_option.add_item("吐纳回蓝 (打坐)")
	mode_option.add_item("参悟功法 (提升法术)")
	mode_option.item_selected.connect(_on_mode_changed)
	
	# Default mode
	_on_mode_changed(0)

func set_player_stats(stats: Node) -> void:
	player_stats = stats
	if player_stats.has_signal("breakthrough_achieved"):
		player_stats.breakthrough_achieved.connect(_on_breakthrough)

func _on_mode_changed(index: int) -> void:
	if index == 0:
		spell_hbox.visible = false
	else:
		spell_hbox.visible = true
		_populate_spells()

func _populate_spells() -> void:
	spell_option.clear()
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var spell_comp = player.get_node_or_null("Spells")
	if not spell_comp: return
	
	for spell_id in spell_comp.unlocked_spells:
		var data = SpellDatabase.get_spell(spell_id)
		var lvl = spell_comp.get_spell_level(spell_id)
		spell_option.add_item(data.get("name", "Unknown") + " (Lv." + str(lvl) + ")")
		spell_option.set_item_metadata(spell_option.item_count - 1, spell_id)

func _on_slider_changed(val: float) -> void:
	year_label.text = str(int(val)) + " 天"

func _on_start_pressed() -> void:
	is_meditating = true
	start_btn.visible = false
	stop_btn.visible = true
	close_btn.disabled = true
	year_slider.editable = false
	mode_option.disabled = true
	spell_option.disabled = true
	
	var days = int(year_slider.value)
	var mode = mode_option.selected
	
	log_label.text += "\n[color=yellow]--- 开始闭关 (" + str(days) + "天) ---[/color]"
	
	# 由于 TimeManager 还在修复中，这里直接进行瞬间岁月跳跃和结算
	# （遵循“疲劳与时间等价公式”：扣除寿命作为灵力税）
	
	if player_stats:
		# 扣除寿元
		player_stats.age_days += days
		if player_stats.has_signal("lifespan_changed"):
			player_stats.lifespan_changed.emit(player_stats.age_days, player_stats.max_age_days)
		
		# 判断模式
		if mode == 0:
			# 回蓝模式
			var base_mana_regen_per_day = 100.0
			var aptitude = player_stats.get("aptitude") if player_stats.get("aptitude") != null else 10
			var total_regen = int(base_mana_regen_per_day * days * (1.0 + aptitude * 0.05))
			if player_stats.has_method("restore_mana"):
				player_stats.restore_mana(total_regen)
			_on_log_received("[color=green]吐纳结束，恢复了 " + str(total_regen) + " 点灵力。[/color]")
			
			# 回蓝时可能附带一点点修为
			if player_stats.has_method("gain_cultivation"):
				player_stats.gain_cultivation(days)
		else:
			# 参悟功法模式
			var comp = player_stats.get("comprehension") if player_stats.get("comprehension") != null else 10
			var xp_gained = days * (10 + comp * 2)
			
			var selected_idx = spell_option.selected
			if selected_idx >= 0:
				var spell_id = spell_option.get_item_metadata(selected_idx)
				var player = get_tree().get_first_node_in_group("player")
				var spell_comp = player.get_node_or_null("Spells") if player else null
				
				if spell_comp and spell_comp.has_method("add_spell_xp"):
					var leveled_up = spell_comp.add_spell_xp(spell_id, xp_gained)
					var new_lvl = spell_comp.get_spell_level(spell_id)
					var spell_name = SpellDatabase.get_spell(spell_id).get("name", "Unknown")
					
					_on_log_received("[color=cyan]参悟了 [" + spell_name + "]，获得 " + str(xp_gained) + " 点法术经验。[/color]")
					if leveled_up:
						_on_log_received("[color=yellow]【法术突破】 [" + spell_name + "] 提升到了 第 " + str(new_lvl) + " 层！[/color]")
						
						var audio = get_node_or_null("/root/AudioManager")
						if audio and audio.has_method("play_sfx"):
							audio.play_sfx("breakthrough")
					
					# 更新下拉框显示
					_populate_spells()
					spell_option.select(selected_idx)
	
	# 瞬间出关
	_finish_meditation()

func _on_stop_pressed() -> void:
	_finish_meditation()

func _finish_meditation() -> void:
	is_meditating = false
	start_btn.visible = true
	stop_btn.visible = false
	close_btn.disabled = false
	year_slider.editable = true
	mode_option.disabled = false
	spell_option.disabled = false

func _on_log_received(msg: String) -> void:
	if not visible: return
	log_label.text += "\n" + msg

func _on_breakthrough(new_level: int) -> void:
	_on_log_received("[color=green]【天道共鸣】修真境界突破了！当前境界达到: " + str(new_level) + "[/color]")

func show_ui() -> void:
	visible = true
	_on_mode_changed(mode_option.selected)
	var player = get_tree().get_first_node_in_group("player")
	var hud = player.get_node_or_null("HUD") if player else null
	if hud and hud.has_method("_update_mouse_state"):
		hud._update_mouse_state()

func hide_ui() -> void:
	if is_meditating:
		_on_stop_pressed()
	visible = false
	var player = get_tree().get_first_node_in_group("player")
	var hud = player.get_node_or_null("HUD") if player else null
	if hud and hud.has_method("_update_mouse_state"):
		hud._update_mouse_state()
