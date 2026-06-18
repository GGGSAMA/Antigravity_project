extends Control
class_name ActionMenuUI

@onready var btn_meditate = $PanelContainer/VBoxContainer/BtnMeditate
@onready var btn_rest = $PanelContainer/VBoxContainer/BtnRest
@onready var btn_telepathy = $PanelContainer/VBoxContainer/BtnTelepathy
@onready var btn_trade = $PanelContainer/VBoxContainer/BtnTrade

func _ready() -> void:
	visible = false
	btn_meditate.pressed.connect(_on_meditate_pressed)
	btn_rest.pressed.connect(_on_rest_pressed)
	btn_telepathy.pressed.connect(_on_telepathy_pressed)
	if btn_trade:
		btn_trade.pressed.connect(_on_trade_pressed)

func show_ui() -> void:
	visible = true
	var player = get_tree().get_first_node_in_group("player")
	var hud = player.get_node_or_null("HUD") if player else null
	if hud and hud.has_method("_update_mouse_state"):
		hud._update_mouse_state()

func hide_ui() -> void:
	visible = false
	var player = get_tree().get_first_node_in_group("player")
	var hud = player.get_node_or_null("HUD") if player else null
	if hud and hud.has_method("_update_mouse_state"):
		hud._update_mouse_state()

func _on_meditate_pressed() -> void:
	# Hide action menu
	hide_ui()
	# Open meditation UI
	var player = get_tree().get_first_node_in_group("player")
	var hud_manager = player.get_node_or_null("HUD") if player else null
	if hud_manager:
		var meditation = hud_manager.get_node_or_null("MeditationUI")
		if meditation:
			meditation.show_ui()

func _on_rest_pressed() -> void:
	hide_ui()
	var player = get_tree().get_first_node_in_group("player")
	var hud_manager = player.get_node_or_null("HUD") if player else null
	if hud_manager and hud_manager.has_method("show_notification"):
		hud_manager.show_notification("你席地而坐，稍作歇息...")
	# TODO: Implement rest logic (restore HP/MP, skip few hours)

func _on_telepathy_pressed() -> void:
	hide_ui()
	var player = get_tree().get_first_node_in_group("player")
	var hud_manager = player.get_node_or_null("HUD") if player else null
	if hud_manager and hud_manager.has_method("show_notification"):
		hud_manager.show_notification("神识未锁定目标，无法传音。")
	# TODO: Implement telepathy UI

func _on_trade_pressed() -> void:
	hide_ui()
	var sm = get_node_or_null("/root/SocialManager")
	var player = get_tree().get_first_node_in_group("player")
	var hud_manager = player.get_node_or_null("HUD") if player else null
	if hud_manager and sm and sm.npc_attributes.size() > 0:
		var trade_ui = hud_manager.get_node_or_null("TradeUI")
		if trade_ui:
			# For testing: select the first NPC
			var first_npc = sm.npc_attributes.values()[0]
			trade_ui.open_trade(first_npc)
			hud_manager._update_mouse_state()
