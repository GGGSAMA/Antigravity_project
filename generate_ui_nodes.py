import os

def create_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\n')

ui_dir = r'entities\player\components\ui'

# 1. UI Styles (Shared Resource)
create_file(f'{ui_dir}\\ui_styles.gd', """
extends Node
class_name UIStyles

static var style_normal: StyleBoxFlat
static var style_hover: StyleBoxFlat
static var style_active: StyleBoxFlat
static var style_equip: StyleBoxFlat

static func init_styles():
	if style_normal != null: return
	
	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.04, 0.04, 0.06, 0.65)
	style_normal.set_corner_radius_all(4)
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color(1, 1, 1, 0.08)
	
	style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.12, 0.16, 0.8)
	style_hover.set_corner_radius_all(4)
	style_hover.border_width_left = 2
	style_hover.border_width_top = 2
	style_hover.border_width_right = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color(1, 1, 1, 0.45)
	
	style_active = StyleBoxFlat.new()
	style_active.bg_color = Color(0.14, 0.14, 0.22, 0.85)
	style_active.set_corner_radius_all(4)
	style_active.border_width_left = 2
	style_active.border_width_top = 2
	style_active.border_width_right = 2
	style_active.border_width_bottom = 2
	style_active.border_color = Color(0.9, 0.7, 0.1, 0.95)
	
	style_equip = StyleBoxFlat.new()
	style_equip.bg_color = Color(0.06, 0.06, 0.08, 0.75)
	style_equip.set_corner_radius_all(4)
	style_equip.border_width_left = 1
	style_equip.border_width_top = 1
	style_equip.border_width_right = 1
	style_equip.border_width_bottom = 1
	style_equip.border_color = Color(0.9, 0.7, 0.1, 0.15)
""")

# 2. Hotbar UI
create_file(f'{ui_dir}\\ui_hotbar.gd', """
extends Control
class_name UIHotbar

@export var hud_manager: Node
var hotbar_comp
var hotbar_grid: HBoxContainer
var active_index: int = 0

func setup(manager, comp, grid):
	hud_manager = manager
	hotbar_comp = comp
	hotbar_grid = grid
	_build_slots()
	update_ui()

func _build_slots():
	for i in range(9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(44, 50)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", UIStyles.style_normal)
		btn.add_theme_stylebox_override("hover", UIStyles.style_hover)
		
		var icon = Label.new()
		icon.name = "Icon"
		icon.anchors_preset = 15
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.horizontal_alignment = 1
		icon.vertical_alignment = 1
		icon.add_theme_font_size_override("font_size", 20)
		btn.add_child(icon)
		
		var qty = Label.new()
		qty.name = "Qty"
		qty.anchors_preset = 3
		qty.anchor_left = 1.0
		qty.anchor_top = 1.0
		qty.anchor_right = 1.0
		qty.anchor_bottom = 1.0
		qty.offset_left = -30
		qty.offset_top = -18
		qty.offset_right = -3
		qty.offset_bottom = -2
		qty.horizontal_alignment = 2
		qty.vertical_alignment = 2
		qty.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
		qty.add_theme_font_size_override("font_size", 10)
		btn.add_child(qty)
		
		btn.pressed.connect(func(): _on_slot_clicked(i))
		hotbar_grid.add_child(btn)

func update_ui():
	for i in range(hotbar_grid.get_child_count()):
		var btn = hotbar_grid.get_child(i) as Button
		var data = hotbar_comp.slots[i]
		
		if i == active_index:
			btn.add_theme_stylebox_override("normal", UIStyles.style_active)
		else:
			btn.add_theme_stylebox_override("normal", UIStyles.style_normal)
			
		var icon = btn.get_node("Icon") as Label
		var qty = btn.get_node("Qty") as Label
		
		if data != null:
			var meta = hud_manager.ItemDatabase.get_item(data.id)
			icon.text = meta.get("icon", "📦")
			qty.text = str(data.qty) if data.qty > 1 else ""
		else:
			icon.text = ""
			qty.text = ""

func _on_slot_clicked(idx: int):
	active_index = idx
	update_ui()

func scroll_hotbar(direction: int):
	if direction > 0:
		active_index = (active_index + 1) % 9
	else:
		active_index = (active_index - 1 + 9) % 9
	update_ui()
""")

# 3. HUD Manager
create_file(f'{ui_dir}\\hud_manager.gd', """
extends CanvasLayer
class_name HUDManager

const ItemDatabase = preload("res://components/item_database.gd")

@onready var notification_label: Label = $NotificationLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var hotbar_panel: ColorRect = $HotbarPanel
@onready var hotbar_grid: HBoxContainer = $HotbarPanel/HotbarGrid

var player
var hotbar_ui: UIHotbar

func _ready():
	await owner.ready
	player = owner
	UIStyles.init_styles()
	
	# init hotbar
	hotbar_ui = UIHotbar.new()
	add_child(hotbar_ui)
	hotbar_ui.setup(self, player.get("hotbar_comp"), hotbar_grid)
	
	var stats = player.get("stats")
	if stats:
		stats.health_changed.connect(_on_health)
		stats.mana_changed.connect(_on_mana)
		_on_health(stats.current_health, stats.max_health)
		_on_mana(stats.current_mana, stats.max_mana)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			hotbar_ui.scroll_hotbar(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			hotbar_ui.scroll_hotbar(1)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		hotbar_ui.active_index = event.keycode - KEY_1
		hotbar_ui.update_ui()
		get_viewport().set_input_as_handled()

func show_notification(text: String):
	if notification_label:
		notification_label.text = text
		notification_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(notification_label, "modulate:a", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_health(curr, mx):
	if health_bar:
		health_bar.max_value = mx
		health_bar.value = curr
		var lbl = health_bar.get_node_or_null("ValueLabel")
		if lbl: lbl.text = str(curr) + "/" + str(mx)

func _on_mana(curr, mx):
	if mana_bar:
		mana_bar.max_value = mx
		mana_bar.value = curr
		var lbl = mana_bar.get_node_or_null("ValueLabel")
		if lbl: lbl.text = str(curr) + "/" + str(mx)
""")

print("Generated UI scripts successfully!")
