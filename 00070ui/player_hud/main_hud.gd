extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var mana_bar: ProgressBar = %ManaBar
@onready var center_cast_bar: ProgressBar = %CenterCastBar
@onready var center_cast_label: Label = %CenterCastBar/Label

var player_stats: Node

func _ready() -> void:
	# Hide cast bar initially
	center_cast_bar.hide()

	# Connect to player stats
	_find_player_stats()

	# Connect to CombatComponent seams
	var player = _get_player_node()
	if player and player.has_node("CombatComponent"):
		var combat = player.get_node("CombatComponent")
		if combat.has_signal("cast_started"):
			combat.cast_started.connect(show_cast_bar)
			combat.cast_updated.connect(update_cast_bar)
			combat.cast_ended.connect(hide_cast_bar)

	_init_spell_icon_ui()

func _get_player_node() -> Node:
	var curr = self
	while curr:
		if curr is CharacterBody3D and curr.name == "Player": return curr
		curr = curr.get_parent()
	return null

var spell_icon_panel: PanelContainer
var spell_icon_label: Label
var spell_name_label: Label

func _init_spell_icon_ui() -> void:
	spell_icon_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style.set_corner_radius_all(40) # 圆形
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.5, 0.2, 0.8)
	spell_icon_panel.add_theme_stylebox_override("panel", style)

	spell_icon_panel.custom_minimum_size = Vector2(80, 80)
	spell_icon_panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	spell_icon_panel.anchor_left = 1.0
	spell_icon_panel.anchor_top = 1.0
	spell_icon_panel.anchor_right = 1.0
	spell_icon_panel.anchor_bottom = 1.0
	spell_icon_panel.offset_left = -120
	spell_icon_panel.offset_top = -180
	spell_icon_panel.offset_right = -40
	spell_icon_panel.offset_bottom = -100

	spell_icon_label = Label.new()
	spell_icon_label.anchors_preset = Control.PRESET_FULL_RECT
	spell_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spell_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	spell_icon_label.add_theme_font_size_override("font_size", 36)
	spell_icon_label.text = "❌"
	spell_icon_panel.add_child(spell_icon_label)

	spell_name_label = Label.new()
	spell_name_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	spell_name_label.anchor_top = 1.0
	spell_name_label.anchor_bottom = 1.0
	spell_name_label.offset_top = 5
	spell_name_label.offset_bottom = 25
	spell_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spell_name_label.add_theme_font_size_override("font_size", 14)
	spell_name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	spell_name_label.text = "无"
	spell_icon_panel.add_child(spell_name_label)

	add_child(spell_icon_panel)

func _find_player_stats() -> void:
	var root = get_tree().root
	var player = root.find_child("Player", true, false)
	if player:
		player_stats = player.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")

	if player_stats:
		player_stats.health_changed.connect(_on_health_changed)
		player_stats.mana_changed.connect(_on_mana_changed)
		_on_health_changed(player_stats.current_health, player_stats.max_health)
		_on_mana_changed(player_stats.current_mana, player_stats.max_mana)

func _process(_delta: float) -> void:
	if not player_stats:
		_find_player_stats()

	# 更新法术 UI
	var root = get_tree().root
	var player = root.find_child("Player", true, false)
	if player:
		var spell_comp = player.get_node_or_null("Spells")
		if spell_comp and spell_icon_label:
			var current_spell = spell_comp.get_active_spell(false)
			if current_spell != null:
				spell_icon_label.text = current_spell.icon
				spell_name_label.text = current_spell.name

				# 呼吸灯效果
				var t = Time.get_ticks_msec() / 1000.0
				var alpha = 0.7 + 0.3 * sin(t * 3.0)
				var style = spell_icon_panel.get_theme_stylebox("panel") as StyleBoxFlat
				var base_color = Color(current_spell.color) if typeof(current_spell.color) == TYPE_STRING else current_spell.color
				style.border_color = Color(base_color.r, base_color.g, base_color.b, alpha)

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func _on_mana_changed(current: int, maximum: int) -> void:
	mana_bar.max_value = maximum
	mana_bar.value = current

# --- Casting UI API ---
func show_cast_bar(spell_name: String, time_max: float) -> void:
	center_cast_bar.max_value = time_max
	center_cast_bar.value = 0
	center_cast_label.text = "施放: " + spell_name
	center_cast_bar.show()

func update_cast_bar(time_current: float) -> void:
	center_cast_bar.value = time_current

func hide_cast_bar() -> void:
	center_cast_bar.hide()

func set_interaction_prompt(text: String, is_visible: bool) -> void:
	var prompt = get_node_or_null("%InteractionPrompt")
	if prompt:
		prompt.text = text
		prompt.visible = is_visible
