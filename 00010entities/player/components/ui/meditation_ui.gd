extends "res://0000core/ui/base_menu_ui.gd"
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
const SpellDatabase = preload("res://00020components/spell_database.gd")
var  layer
func _ready() -> void:
	super._ready()
	layer = 51 # Above Dashboard
	
	year_slider.value_changed.connect(_on_slider_changed)
	start_btn.pressed.connect(_on_start_pressed)
	stop_btn.pressed.connect(_on_stop_pressed)
	close_btn.pressed.connect(close_ui)
	
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
	
	var years = int(year_slider.value)
	var mode = mode_option.selected
	
	log_label.text += "\n[color=yellow]--- 开始闭关 (" + str(years) + "年) ---[/color]"
	
	# === 真正的架构：状态注入与全局流逝 ===
	var player = get_tree().get_first_node_in_group("player")
	var activity_mgr = player.get_node_or_null("PlayerActivityManager") if player else null
	
	if activity_mgr:
		if mode == 0:
			activity_mgr.start_activity("meditate")
		else:
			var selected_idx = spell_option.selected
			if selected_idx >= 0:
				var spell_id = spell_option.get_item_metadata(selected_idx)
				activity_mgr.start_activity("comprehend", {"spell_id": spell_id})
	
	# 调用异步岁月流逝(带有读条体验)，挂起本协程等待结束 (年转化为小时)
	if TimeManager and TimeManager.has_method("skip_time_async"):
		await TimeManager.skip_time_async(years * 365.0 * 24.0, "闭关推演中...")
	
	if activity_mgr:
		activity_mgr.clear_activity()
	
	# 岁月跳跃完毕，出关
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

func open_ui() -> void:
	super.open_ui()
	_on_mode_changed(mode_option.selected)

func close_ui() -> void:
	if is_meditating:
		_on_stop_pressed()
	super.close_ui()
	var player = get_tree().get_first_node_in_group("player")
	var hud = player.get_node_or_null("HUD") if player else null
	if hud and hud.has_method("_update_mouse_state"):
		hud._update_mouse_state()
