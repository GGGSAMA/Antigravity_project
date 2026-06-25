import os
import re

ui_dir = r'entities\player\components\ui'
os.makedirs(ui_dir, exist_ok=True)

# 1. UI Styles
with open(f'{ui_dir}/ui_styles.gd', 'w', encoding='utf-8') as f:
    f.write("""extends Node
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
	
	style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.12, 0.12, 0.16, 0.8)
	style_hover.border_color = Color(1, 1, 1, 0.45)
	
	style_active = style_normal.duplicate()
	style_active.bg_color = Color(0.14, 0.14, 0.22, 0.85)
	style_active.border_color = Color(0.9, 0.7, 0.1, 0.95)
	
	style_equip = style_normal.duplicate()
	style_equip.bg_color = Color(0.06, 0.06, 0.08, 0.75)
	style_equip.border_color = Color(0.9, 0.7, 0.1, 0.15)
""")

# 2. HUD Manager
with open(f'{ui_dir}/hud_manager.gd', 'w', encoding='utf-8') as f:
    f.write("""extends CanvasLayer
class_name HUDManager

@onready var notification_label: Label = $NotificationLabel
@onready var inventory_panel: ColorRect = $InventoryPanel

func _ready():
	UIStyles.init_styles()
	if notification_label:
		notification_label.modulate.a = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		toggle_panel(inventory_panel)
		get_viewport().set_input_as_handled()

func toggle_panel(panel: Control):
	if panel:
		panel.visible = !panel.visible
		if panel.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_notification(text: String):
	if notification_label:
		notification_label.text = text
		notification_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(notification_label, "modulate:a", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
""")

# 3. Status Bars UI
with open(f'{ui_dir}/status_bars_ui.gd', 'w', encoding='utf-8') as f:
    f.write("""extends Control
class_name StatusBarsUI

@onready var health_bar: ProgressBar = $"../HealthBar" if get_node_or_null("../HealthBar") else null
@onready var mana_bar: ProgressBar = $"../ManaBar" if get_node_or_null("../ManaBar") else null
@onready var hud = get_parent()
var stats

func _ready():
	await owner.ready
	stats = owner.get("stats")
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.mana_changed.connect(_on_mana_changed)
		_on_health_changed(stats.current_health, stats.max_health)
		_on_mana_changed(stats.current_mana, stats.max_mana)

func _on_health_changed(current: int, maximum: int):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		var lbl = health_bar.get_node_or_null("ValueLabel")
		if lbl: lbl.text = str(current) + "/" + str(maximum)

func _on_mana_changed(current: int, maximum: int):
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current
		var lbl = mana_bar.get_node_or_null("ValueLabel")
		if lbl: lbl.text = str(current) + "/" + str(maximum)
""")

# 4. Hotbar UI
with open(f'{ui_dir}/hotbar_ui.gd', 'w', encoding='utf-8') as f:
    f.write("""extends ColorRect
class_name HotbarUI

@onready var grid: HBoxContainer = $HotbarGrid
var hotbar_comp
var active_index: int = 0
const ItemDatabase = preload("res://components/item_database.gd")

func _ready():
	await owner.ready
	hotbar_comp = owner.get("hotbar_comp")
	if not hotbar_comp: return
	
	_build_slots()
	update_ui()
	
	# Listen for global inventory changes (simplification)
	# Ideally hotbar_comp should emit signals, but we can poll for now or hook into actions.

func _build_slots():
	for child in grid.get_children():
		child.queue_free()
	
	for i in range(hotbar_comp.size):
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
		grid.add_child(btn)

func update_ui():
	for i in range(grid.get_child_count()):
		var btn = grid.get_child(i)
		var item = hotbar_comp.slots[i]
		
		if i == active_index:
			btn.add_theme_stylebox_override("normal", UIStyles.style_active)
		else:
			btn.add_theme_stylebox_override("normal", UIStyles.style_normal)
			
		var icon = btn.get_node("Icon")
		var qty = btn.get_node("Qty")
		
		if item:
			var meta = ItemDatabase.get_item(item.id)
			icon.text = meta.get("icon", "📦")
			qty.text = str(item.qty) if item.qty > 1 else ""
		else:
			icon.text = ""
			qty.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			active_index = (active_index - 1 + hotbar_comp.size) % hotbar_comp.size
			update_ui()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			active_index = (active_index + 1) % hotbar_comp.size
			update_ui()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var target = event.keycode - KEY_1
		if target < hotbar_comp.size:
			active_index = target
			update_ui()
			get_viewport().set_input_as_handled()

func _on_slot_clicked(idx: int):
	active_index = idx
	update_ui()
""")

# 5. Inventory UI
with open(f'{ui_dir}/inventory_ui.gd', 'w', encoding='utf-8') as f:
    f.write("""extends ColorRect
class_name InventoryUI

@onready var bag_grid: GridContainer = $BagGrid
@onready var equip_grid: GridContainer = $EquipmentGrid
var inventory_comp
var equipment_comp
const ItemDatabase = preload("res://components/item_database.gd")

func _ready():
	await owner.ready
	inventory_comp = owner.get("inventory_comp")
	equipment_comp = owner.get("equipment_comp")
	
	if inventory_comp:
		_build_bag_slots()
	if equipment_comp:
		_build_equip_slots()
		
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		update_ui()

func _build_bag_slots():
	for child in bag_grid.get_children(): child.queue_free()
	for i in range(inventory_comp.size):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 44)
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
		qty.horizontal_alignment = 2
		qty.vertical_alignment = 2
		qty.add_theme_font_size_override("font_size", 11)
		btn.add_child(qty)
		
		btn.pressed.connect(func(): _on_bag_clicked(i))
		bag_grid.add_child(btn)

func _build_equip_slots():
	for child in equip_grid.get_children(): child.queue_free()
	var names = ["⚔️ 武器", "🥋 法衣", "🛡️ 盾牌", "📿 法宝"]
	for i in range(4):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 44)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", UIStyles.style_equip)
		btn.add_theme_stylebox_override("hover", UIStyles.style_hover)
		
		var lbl = Label.new()
		lbl.name = "Title"
		lbl.text = names[i]
		lbl.anchors_preset = 15
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 1.0
		lbl.horizontal_alignment = 1
		lbl.vertical_alignment = 1
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
		btn.add_child(lbl)
		
		var icon = Label.new()
		icon.name = "Icon"
		icon.anchors_preset = 15
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.horizontal_alignment = 1
		icon.vertical_alignment = 1
		icon.add_theme_font_size_override("font_size", 20)
		btn.add_child(icon)
		
		btn.pressed.connect(func(): _on_equip_clicked(i))
		equip_grid.add_child(btn)

func update_ui():
	if not inventory_comp or not equipment_comp: return
	
	# Bag
	for i in range(bag_grid.get_child_count()):
		var btn = bag_grid.get_child(i)
		var item = inventory_comp.slots[i]
		var icon = btn.get_node("Icon")
		var qty = btn.get_node("Qty")
		if item:
			var meta = ItemDatabase.get_item(item.id)
			icon.text = meta.get("icon", "📦")
			qty.text = str(item.qty) if item.qty > 1 else ""
		else:
			icon.text = ""
			qty.text = ""
			
	# Equip
	for i in range(equip_grid.get_child_count()):
		var btn = equip_grid.get_child(i)
		var item = equipment_comp.slots[i]
		var icon = btn.get_node("Icon")
		var title = btn.get_node("Title")
		if item:
			var meta = ItemDatabase.get_item(item.id)
			icon.text = meta.get("icon", "📦")
			title.text = ""
		else:
			icon.text = ""
			var names = ["⚔️ 武器", "🥋 法衣", "🛡️ 盾牌", "📿 法宝"]
			title.text = names[i]

func _on_bag_clicked(idx: int):
	# Simplest logic: if item is equipment, try to equip it. If consumable, consume it.
	var item = inventory_comp.slots[idx]
	if not item: return
	
	var meta = ItemDatabase.get_item(item.id)
	var type = meta.get("type", "potion")
	
	if type == "weapon":
		# Swap with equip slot 0
		var old_equip = equipment_comp.slots[0]
		equipment_comp.set_slot(0, item.id, 1)
		inventory_comp.set_slot(idx, null, 0)
		if old_equip:
			inventory_comp.set_slot(idx, old_equip.id, 1)
		update_ui()
		var manager = get_parent()
		if manager.has_method("show_notification"):
			manager.show_notification("装备了: " + str(meta.name if meta.name else item.id))
	else:
		# Consume potion
		if inventory_comp.remove_item(item.id, 1):
			var stats = owner.get("stats")
			if stats and meta.has("effects"):
				var eff = meta.effects
				if eff.has("heal"): stats.heal(eff.heal)
				if eff.has("mana"): stats.restore_mana(eff.mana)
			update_ui()

func _on_equip_clicked(idx: int):
	# Unequip to first available bag slot
	var item = equipment_comp.slots[idx]
	if not item: return
	
	# Find empty bag slot
	for i in range(inventory_comp.size):
		if inventory_comp.slots[i] == null:
			inventory_comp.set_slot(i, item.id, 1)
			equipment_comp.set_slot(idx, null, 0)
			update_ui()
			return
""")

# Inject the scripts into player.tscn
with open(r'entities\player\player.tscn', 'r', encoding='utf-8') as f:
    tscn_text = f.read()

# Remove old UI controller script reference
tscn_text = re.sub(r'ext_resource type="Script" path="res://entities/player/components/ui_controller_v3.gd" id="\d+"_\w+"\n', '', tscn_text)

# Add new script resources
script_defs = """[ext_resource type="Script" path="res://entities/player/components/ui/hud_manager.gd" id="20_hud"]
[ext_resource type="Script" path="res://entities/player/components/ui/inventory_ui.gd" id="21_inv"]
[ext_resource type="Script" path="res://entities/player/components/ui/hotbar_ui.gd" id="22_hot"]
[ext_resource type="Script" path="res://entities/player/components/ui/status_bars_ui.gd" id="23_stat"]
"""

# Insert script defs at the end of ext_resources
match = re.search(r'(\[ext_resource.*?\]\n)(?!\[ext_resource)', tscn_text, re.DOTALL)
if match:
    insert_pos = match.end()
    tscn_text = tscn_text[:insert_pos] + script_defs + tscn_text[insert_pos:]
else:
    tscn_text = script_defs + tscn_text

# Attach scripts to nodes
tscn_text = re.sub(r'\[node name="HUD" type="CanvasLayer" parent="."\]', r'[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("20_hud")', tscn_text)
tscn_text = re.sub(r'\[node name="InventoryPanel" type="ColorRect" parent="HUD"\]', r'[node name="InventoryPanel" type="ColorRect" parent="HUD"]\nscript = ExtResource("21_inv")', tscn_text)
tscn_text = re.sub(r'\[node name="HotbarPanel" type="ColorRect" parent="HUD"\]', r'[node name="HotbarPanel" type="ColorRect" parent="HUD"]\nscript = ExtResource("22_hot")', tscn_text)
# We will attach StatusBarsUI to HUD itself, to manage both bars
tscn_text = re.sub(r'script = ExtResource\("20_hud"\)', r'script = ExtResource("20_hud")\n\n[node name="StatusBars" type="Control" parent="HUD"]\nscript = ExtResource("23_stat")', tscn_text)

with open(r'entities\player\player.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn_text)

print("Decoupled UI created successfully!")
