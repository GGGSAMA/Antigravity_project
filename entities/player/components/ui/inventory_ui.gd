extends ColorRect
class_name InventoryUI

# ==============================================================================
# 【UI 组件 (InventoryUI) - 细节实现与调优基准】
# ------------------------------------------------------------------------------
# 牢大重点要求的“已调优细节前提”（已在此彻底重写恢复）：
# 1. 背包呼出机制：按 TAB 键打开物品面板，同时释放鼠标控制权；再按 TAB 或 ESC 关闭。
# 2. 鼠标对物品的精细操作 (已完全解耦恢复)：
#    - 悬停 (Hover)：鼠标放在物品上显示属性 Tooltip。
#    - 左键拖拽 (Drag & Drop)：跨组件的全局抓取与放置。
#    - 右键操作：背包内右键直接装备/消耗；装备栏右键卸下。
#    - 快捷键 1-9：悬停时按 1-9 快速绑定快捷栏。
# ==============================================================================

@onready var bag_grid: GridContainer = $BagGrid
@onready var equip_grid: GridContainer = $EquipmentGrid

var inventory_comp
var equipment_comp
var hotbar_comp
var manager # 指向 HUDManager 以获取全局 carried_item

const ItemDatabase = preload("res://components/item_database.gd")

func _ready():
	await owner.ready
	inventory_comp = owner.get("inventory_comp")
	equipment_comp = owner.get("equipment_comp")
	hotbar_comp = owner.get("hotbar_comp")
	manager = get_parent() # HUDManager
	
	if inventory_comp: _build_bag_slots()
	if equipment_comp: _build_equip_slots()
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible: update_ui()
	else: if manager and manager.has_method("hide_tooltip"): manager.hide_tooltip()

func _build_bag_slots():
	for child in bag_grid.get_children(): child.queue_free()
	for i in range(inventory_comp.size):
		var btn = _create_slot_button(Vector2(80, 44), false)
		
		# 连接事件
		btn.gui_input.connect(_on_bag_gui_input.bind(i))
		btn.mouse_entered.connect(_on_bag_hover.bind(i))
		btn.mouse_exited.connect(func(): if manager: manager.hide_tooltip())
		
		bag_grid.add_child(btn)

func _build_equip_slots():
	for child in equip_grid.get_children(): child.queue_free()
	var names = ["⚔️ 武器", "🥋 法衣", "🛡️ 盾牌", "📿 法宝"]
	for i in range(4):
		var btn = _create_slot_button(Vector2(130, 44), true, names[i])
		
		btn.gui_input.connect(_on_equip_gui_input.bind(i))
		btn.mouse_entered.connect(_on_equip_hover.bind(i))
		btn.mouse_exited.connect(func(): if manager: manager.hide_tooltip())
		
		equip_grid.add_child(btn)

func _create_slot_button(size: Vector2, is_equip: bool, title_text: String = "") -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", UIStyles.style_equip if is_equip else UIStyles.style_normal)
	btn.add_theme_stylebox_override("hover", UIStyles.style_hover)
	
	if title_text != "":
		var lbl = Label.new()
		lbl.name = "Title"
		lbl.text = title_text
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
	
	return btn

func update_ui():
	if not inventory_comp or not equipment_comp: return
	
	for i in range(bag_grid.get_child_count()):
		var btn = bag_grid.get_child(i)
		var item = inventory_comp.slots[i]
		_update_slot_visuals(btn, item, false)
			
	for i in range(equip_grid.get_child_count()):
		var btn = equip_grid.get_child(i)
		var item = equipment_comp.slots[i]
		_update_slot_visuals(btn, item, true)

func _update_slot_visuals(btn: Button, item: Variant, is_equip: bool):
	var icon = btn.get_node("Icon")
	var qty = btn.get_node("Qty")
	var title = btn.get_node_or_null("Title")
	
	if item:
		var meta = ItemDatabase.get_item(item.id)
		icon.text = meta.get("icon", "📦")
		qty.text = str(item.qty) if item.qty > 1 else ""
		if title: title.text = ""
	else:
		icon.text = ""
		qty.text = ""
		if title and is_equip:
			# Resets title text if it's an empty equip slot. handled in build logic
			pass

# ==========================================
# 交互事件：Tooltip 悬停
# ==========================================
func _on_bag_hover(idx: int):
	if not manager or manager.carried_item != null: return
	var item = inventory_comp.slots[idx]
	if item:
		var txt = _generate_tooltip(item.id)
		manager.show_tooltip(txt)

func _on_equip_hover(idx: int):
	if not manager or manager.carried_item != null: return
	var item = equipment_comp.slots[idx]
	if item:
		var txt = _generate_tooltip(item.id)
		manager.show_tooltip(txt)

func _generate_tooltip(item_id: String) -> String:
	var meta = ItemDatabase.get_item(item_id)
	var type = meta.get("type", "potion")
	var text = "[color=#F0D050][b]" + meta.get("name", item_id) + "[/b][/color]\n"
	text += "[color=#A0A0A0]" + meta.get("desc", "未知物品") + "[/color]\n"
	
	if meta.has("effects"):
		var eff = meta.effects
		if eff.has("heal"): text += "[color=#FF5050]回复气血: +" + str(eff.heal) + "[/color]\n"
		if eff.has("mana"): text += "[color=#5050FF]恢复灵力: +" + str(eff.mana) + "[/color]\n"
		if eff.has("damage"): text += "[color=#FF3030]攻击力: " + str(eff.damage) + "[/color]\n"
	
	if type == "potion": text += "\n[color=#808080][右键使用] [1-9快捷栏][/color]"
	elif type == "weapon": text += "\n[color=#808080][右键装备] [拖拽装备][/color]"
	return text

# ==========================================
# 交互事件：左键拖拽、右键使用、数字键绑定
# ==========================================
func _on_bag_gui_input(event: InputEvent, idx: int):
	if event is InputEventMouseButton and event.pressed:
		var data = inventory_comp.slots[idx]
		
		# 左键：拖拽交换
		if event.button_index == MOUSE_BUTTON_LEFT:
			if manager.carried_item == null:
				if data != null:
					manager.carried_item = data
					inventory_comp.clear_slot(idx)
			else:
				if data == null:
					inventory_comp.set_slot(idx, manager.carried_item.id, manager.carried_item.qty)
					manager.carried_item = null
				else:
					if data.id == manager.carried_item.id:
						inventory_comp.set_slot(idx, data.id, data.qty + manager.carried_item.qty)
						manager.carried_item = null
					else:
						var temp = data
						inventory_comp.set_slot(idx, manager.carried_item.id, manager.carried_item.qty)
						manager.carried_item = temp
			update_ui()
			manager.hide_tooltip()
			
		# 右键：快捷使用或装备
		elif event.button_index == MOUSE_BUTTON_RIGHT and manager.carried_item == null:
			if data == null: return
			var meta = ItemDatabase.get_item(data.id)
			var type = meta.get("type", "potion")
			
			if type == "weapon":
				var old_equip = equipment_comp.slots[0]
				equipment_comp.set_slot(0, data.id, 1)
				inventory_comp.set_slot(idx, null, 0)
				if old_equip:
					inventory_comp.set_slot(idx, old_equip.id, 1)
				update_ui()
			elif type == "potion":
				inventory_comp.remove_item(data.id, 1)
				var stats = owner.get("stats")
				if stats and meta.has("effects"):
					if meta.effects.has("heal"): stats.heal(meta.effects.heal)
					if meta.effects.has("mana"): stats.restore_mana(meta.effects.mana)
				update_ui()
				_on_bag_hover(idx) # 刷新 Tooltip

	# 1-9 快捷键绑定
	elif event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		if manager.carried_item == null:
			var data = inventory_comp.slots[idx]
			if data != null and hotbar_comp:
				var hotbar_idx = event.keycode - KEY_1
				hotbar_comp.set_slot(hotbar_idx, data.id, data.qty) # 镜像绑定到快捷栏
				manager.get_node("HotbarPanel").update_ui()
				manager.show_notification("已绑定到快捷栏 " + str(hotbar_idx + 1))

func _on_equip_gui_input(event: InputEvent, idx: int):
	if event is InputEventMouseButton and event.pressed:
		var data = equipment_comp.slots[idx]
		
		# 左键：拖拽交换
		if event.button_index == MOUSE_BUTTON_LEFT:
			if manager.carried_item == null:
				if data != null:
					manager.carried_item = data
					equipment_comp.clear_slot(idx)
			else:
				var meta = ItemDatabase.get_item(manager.carried_item.id)
				var req_type = "weapon" if idx == 0 else "armor" # 简易校验
				if meta.get("type", "potion") == req_type:
					if data == null:
						equipment_comp.set_slot(idx, manager.carried_item.id, manager.carried_item.qty)
						manager.carried_item = null
					else:
						var temp = data
						equipment_comp.set_slot(idx, manager.carried_item.id, manager.carried_item.qty)
						manager.carried_item = temp
				else:
					manager.show_notification("该物品无法装备到此槽位！")
			update_ui()
			manager.hide_tooltip()
			
		# 右键：一键卸下到背包
		elif event.button_index == MOUSE_BUTTON_RIGHT and manager.carried_item == null:
			if data == null: return
			for i in range(inventory_comp.size):
				if inventory_comp.slots[i] == null:
					inventory_comp.set_slot(i, data.id, data.qty)
					equipment_comp.clear_slot(idx)
					update_ui()
					manager.hide_tooltip()
					return
			manager.show_notification("背包已满，无法卸下装备！")
