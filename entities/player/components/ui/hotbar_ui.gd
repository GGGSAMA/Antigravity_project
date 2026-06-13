extends ColorRect
class_name HotbarUI

@onready var grid: HBoxContainer = $HotbarGrid
var hotbar_comp
var active_index: int = 0
var manager # 指向 HUDManager

const ItemDatabase = preload("res://components/item_database.gd")

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if not player.is_node_ready():
			await player.ready
		hotbar_comp = player.get("hotbar_comp")
		manager = player.get_node_or_null("HUD")
	
	if not manager:
		manager = get_node_or_null("/root/GameRoot/Player/HUD")
	if not hotbar_comp: return
	
	_build_slots()
	update_ui()

func _build_slots():
	for child in grid.get_children():
		child.queue_free()
	
	for i in range(hotbar_comp.size):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(44, 50)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.flat = true
		
		var bg = ColorRect.new()
		bg.name = "Background"
		bg.color = Color(0.1, 0.1, 0.15, 0.9)
		bg.anchors_preset = 15
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(bg)
		
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
		
		btn.gui_input.connect(_on_slot_gui_input.bind(i))
		btn.mouse_entered.connect(_on_slot_hover.bind(i))
		btn.mouse_exited.connect(func(): if manager: manager.hide_tooltip())
		grid.add_child(btn)

func update_ui():
	var active_idx = hotbar_comp.active_slot_index if hotbar_comp else 0
	for i in range(grid.get_child_count()):
		var btn = grid.get_child(i)
		var item = hotbar_comp.slots[i]
		
		var bg = btn.get_node("Background")
		if i == active_idx:
			bg.color = Color(0.4, 0.35, 0.2, 0.9) # Active style
		else:
			bg.color = Color(0.1, 0.1, 0.15, 0.9) # Normal style
		var icon = btn.get_node("Icon")
		var qty = btn.get_node("Qty")
		
		if item:
			var meta = ItemDatabase.get_item(item.id)
			icon.text = meta.get("icon", "📦")
			qty.text = str(item.qty) if item.qty > 1 else ""
		else:
			icon.text = ""
			qty.text = ""

func _on_slot_hover(idx: int):
	if not manager or manager.carried_item != null: return
	var item = hotbar_comp.slots[idx]
	if item:
		var meta = ItemDatabase.get_item(item.id)
		var text = "[color=#F0D050][b]" + meta.get("name", item.id) + "[/b][/color]\n"
		text += "[color=#A0A0A0]" + meta.get("desc", "未知物品") + "[/color]\n"
		manager.show_tooltip(text)

func _on_slot_gui_input(event: InputEvent, idx: int):
	if event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 如果背包打开了，允许拖拽物品到快捷栏
			if manager and manager.inventory_panel.visible:
				var data = hotbar_comp.slots[idx]
				if manager.carried_item == null:
					if data != null:
						manager.carried_item = data
						hotbar_comp.clear_slot(idx)
				else:
					if data == null:
						hotbar_comp.set_slot(idx, manager.carried_item.id, manager.carried_item.qty)
						manager.carried_item = null
					else:
						if data.id == manager.carried_item.id:
							hotbar_comp.set_slot(idx, data.id, data.qty + manager.carried_item.qty)
							manager.carried_item = null
						else:
							var temp = data
							hotbar_comp.set_slot(idx, manager.carried_item.id, manager.carried_item.qty)
							manager.carried_item = temp
				update_ui()
				manager.hide_tooltip()
			else:
				# 正常游戏中，点击直接选中快捷栏
				hotbar_comp.set_active_slot(idx)
				update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not hotbar_comp: return
	if event is InputEventMouseButton and event.pressed:
		var current = hotbar_comp.active_slot_index
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			hotbar_comp.set_active_slot((current - 1 + hotbar_comp.size) % hotbar_comp.size)
			update_ui()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			hotbar_comp.set_active_slot((current + 1) % hotbar_comp.size)
			update_ui()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var target = event.keycode - KEY_1
		if target < hotbar_comp.size:
			hotbar_comp.set_active_slot(target)
			update_ui()
			get_viewport().set_input_as_handled()
