extends ColorRect
class_name LootContainerUI

@onready var player_grid: GridContainer = $HBox/PlayerPanel/Scroll/PlayerGrid
@onready var container_grid: GridContainer = $HBox/ContainerPanel/Scroll/ContainerGrid
@onready var btn_take_all: Button = $HBox/ContainerPanel/Header/BtnTakeAll
@onready var btn_close: Button = $HBox/ContainerPanel/Header/BtnClose

var inventory_comp: Node
var loot_comp: Node
var manager: Node

const ItemDatabase = preload("res://0000core/data/item_database.gd")

func _ready() -> void:
	color = Color(0, 0, 0, 0.8)
	
	btn_take_all.pressed.connect(_on_take_all_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	
	visibility_changed.connect(_on_visibility_changed)

func setup(p_inventory: Node, p_loot: Node, p_manager: Node) -> void:
	inventory_comp = p_inventory
	loot_comp = p_loot
	manager = p_manager
	
	if inventory_comp:
		if not inventory_comp.slots_changed.is_connected(update_ui.unbind(2)):
			inventory_comp.slots_changed.connect(update_ui.unbind(2))
	if loot_comp:
		if not loot_comp.slots_changed.is_connected(update_ui.unbind(2)):
			loot_comp.slots_changed.connect(update_ui.unbind(2))
			
	_build_grids()
	update_ui()

func _on_visibility_changed() -> void:
	if visible:
		update_ui()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if manager and manager.has_method("hide_tooltip"):
			manager.hide_tooltip()

func _build_grids() -> void:
	for child in player_grid.get_children(): child.queue_free()
	for child in container_grid.get_children(): child.queue_free()
	
	if inventory_comp:
		for i in range(inventory_comp.size):
			var btn = _create_slot_button()
			btn.gui_input.connect(_on_player_slot_input.bind(i))
			btn.mouse_entered.connect(_on_slot_hover.bind(i, true))
			btn.mouse_exited.connect(func(): if manager: manager.hide_tooltip())
			player_grid.add_child(btn)
			
	if loot_comp:
		for i in range(loot_comp.size):
			var btn = _create_slot_button()
			btn.gui_input.connect(_on_container_slot_input.bind(i))
			btn.mouse_entered.connect(_on_slot_hover.bind(i, false))
			btn.mouse_exited.connect(func(): if manager: manager.hide_tooltip())
			container_grid.add_child(btn)

func _create_slot_button() -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.focus_mode = Control.FOCUS_NONE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.15, 0.12, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.28, 0.2, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	
	var icon = Label.new()
	icon.name = "Icon"
	icon.anchors_preset = Control.PRESET_FULL_RECT
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32)
	btn.add_child(icon)
	
	var qty = Label.new()
	qty.name = "Qty"
	qty.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	qty.anchor_left = 1.0
	qty.anchor_top = 1.0
	qty.anchor_right = 1.0
	qty.anchor_bottom = 1.0
	qty.offset_right = -4
	qty.offset_bottom = -2
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty.add_theme_font_size_override("font_size", 14)
	btn.add_child(qty)
	
	return btn

func update_ui() -> void:
	if not visible: return
	if not inventory_comp or not loot_comp: return
	
	for i in range(player_grid.get_child_count()):
		_update_slot_visuals(player_grid.get_child(i), inventory_comp.slots[i])
		
	for i in range(container_grid.get_child_count()):
		_update_slot_visuals(container_grid.get_child(i), loot_comp.slots[i])

func _update_slot_visuals(btn: Button, item: Variant) -> void:
	var icon = btn.get_node("Icon")
	var qty = btn.get_node("Qty")
	var style = btn.get_theme_stylebox("normal") as StyleBoxFlat
	
	if item:
		var meta = ItemDatabase.get_item(item.get_item_id())
		icon.text = meta.icon
		qty.text = str(item.qty) if item.qty > 1 else ""
		
		var q = item.quality
		if q == 1: style.border_color = Color(0.2, 0.8, 0.2, 1)
		elif q == 2: style.border_color = Color(0.2, 0.5, 0.9, 1)
		elif q >= 3: style.border_color = Color(0.8, 0.2, 0.8, 1)
		else: style.border_color = Color(0.6, 0.6, 0.6, 1)
	else:
		icon.text = ""
		qty.text = ""
		style.border_color = Color(0.35, 0.28, 0.2, 1)

func _on_slot_hover(idx: int, is_player: bool) -> void:
	if not manager or manager.carried_item != null: return
	var comp = inventory_comp if is_player else loot_comp
	var item = comp.slots[idx]
	if item:
		var item_id = item.get_item_id()
		var meta = ItemDatabase.get_item(item_id)
		manager.show_tooltip("[b]" + (meta.name if meta.name != "" else item_id) + "[/b]\n[color=#A0A0A0]" + meta.desc + "[/color]")

func _on_player_slot_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var data = inventory_comp.slots[idx]
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				# Shift-click: instant transfer to container
				if data != null:
					if loot_comp.add_item(data.get_item_id(), data.qty, {"affixes": data.affixes, "quality": data.quality}):
						inventory_comp.clear_slot(idx)
			else:
				# Normal drag drop
				_handle_drag_drop(inventory_comp, idx, data)
				
		get_viewport().set_input_as_handled()

func _on_container_slot_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var data = loot_comp.slots[idx]
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				# Shift-click: instant transfer to player
				if data != null:
					if inventory_comp.add_item(data.get_item_id(), data.qty, {"affixes": data.affixes, "quality": data.quality}):
						loot_comp.clear_slot(idx)
			else:
				# Normal drag drop
				_handle_drag_drop(loot_comp, idx, data)
				
		get_viewport().set_input_as_handled()

func _handle_drag_drop(comp: Node, idx: int, data: Variant) -> void:
	if manager.carried_item == null:
		if data != null:
			manager.carried_item = data
			comp.clear_slot(idx)
	else:
		if data == null:
			comp.set_slot(idx, manager.carried_item.get_item_id(), manager.carried_item.qty, {"affixes": manager.carried_item.affixes, "quality": manager.carried_item.quality})
			manager.carried_item = null
		else:
			if data.get_item_id() == manager.carried_item.get_item_id() and data.affixes.is_empty() and manager.carried_item.affixes.is_empty():
				comp.set_slot(idx, data.get_item_id(), data.qty + manager.carried_item.qty)
				manager.carried_item = null
			else:
				var temp = data
				comp.set_slot(idx, manager.carried_item.get_item_id(), manager.carried_item.qty, {"affixes": manager.carried_item.affixes, "quality": manager.carried_item.quality})
				manager.carried_item = temp
	update_ui()
	manager.hide_tooltip()

func _on_take_all_pressed() -> void:
	if not loot_comp or not inventory_comp: return
	for i in range(loot_comp.size):
		var item = loot_comp.slots[i]
		if item:
			if inventory_comp.add_item(item.get_item_id(), item.qty, {"affixes": item.affixes, "quality": item.quality}):
				loot_comp.clear_slot(i)
	update_ui()

func _on_close_pressed() -> void:
	if UIFocusManager:
		UIFocusManager.pop_ui(self)
	else:
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
