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

@onready var bag_grid: GridContainer = $ContentContainer/RightPanel/ScrollContainer/BagGrid
@onready var equip_grid: Control = $ContentContainer/LeftPanel/EquipmentGrid

var inventory_comp
var equipment_comp
var hotbar_comp
var manager # 指向 HUDManager 以获取全局 carried_item

const ItemDatabase = preload("res://0000core/data/item_database.gd")

func _ready():
	var old_tabs = get_node_or_null("TopTabs")
	if old_tabs:
		old_tabs.hide()
		old_tabs.queue_free()
	# 延迟初始化，避免在 reparent 的瞬间被 await 中断导致组件没有构建完毕
	call_deferred("_init_ui")

func _init_ui():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("/root/GameRoot/Player")

	if player:
		if not player.is_node_ready():
			await player.ready
		inventory_comp = player.get("inventory_comp")
		equipment_comp = player.get("equipment_comp")
		hotbar_comp = player.get("hotbar_comp")
		manager = player.get_node_or_null("HUD")

	if not manager:
		manager = get_node_or_null("/root/GameRoot/Player/HUD")

	if inventory_comp: 
		_build_bag_slots()
		if not inventory_comp.slots_changed.is_connected(update_ui.unbind(2)):
			inventory_comp.slots_changed.connect(update_ui.unbind(2))

	if equipment_comp: 
		_build_equip_slots()
		if not equipment_comp.slots_changed.is_connected(update_ui.unbind(2)):
			equipment_comp.slots_changed.connect(update_ui.unbind(2))

	visibility_changed.connect(_on_visibility_changed)
	if visible: update_ui()

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
	var pos = [
		Vector2(280, 260), # Weapon
		Vector2(280, 50),  # Armor
		Vector2(20, 50),   # Shield
		Vector2(20, 260)   # Artifact
	]
	for i in range(4):
		var btn = _create_slot_button(Vector2(90, 90), true, names[i])
		btn.position = pos[i]

		btn.gui_input.connect(_on_equip_gui_input.bind(i))
		btn.mouse_entered.connect(_on_equip_hover.bind(i))
		btn.mouse_exited.connect(func(): if manager: manager.hide_tooltip())

		equip_grid.add_child(btn)

func _create_slot_button(size: Vector2, is_equip: bool, title_text: String = "") -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.95) if is_equip else Color(0.18, 0.15, 0.12, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.28, 0.2, 1) # Default wood border
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 3

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)

	if title_text != "":
		var lbl = Label.new()
		lbl.name = "Title"
		lbl.text = title_text
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.anchors_preset = 15
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 1.0
		lbl.horizontal_alignment = 1
		lbl.vertical_alignment = 0 # Top aligned
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 0.8))
		btn.add_child(lbl)

	var icon = Label.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.anchors_preset = 15
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.horizontal_alignment = 1
	icon.vertical_alignment = 1
	icon.add_theme_font_size_override("font_size", 32 if is_equip else 24)
	btn.add_child(icon)

	var qty = Label.new()
	qty.name = "Qty"
	qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qty.anchors_preset = 3
	qty.anchor_left = 1.0
	qty.anchor_top = 1.0
	qty.anchor_right = 1.0
	qty.anchor_bottom = 1.0
	qty.offset_right = -4
	qty.offset_bottom = -2
	qty.horizontal_alignment = 2
	qty.vertical_alignment = 2
	qty.add_theme_font_size_override("font_size", 14)
	qty.add_theme_color_override("font_color", Color(1, 1, 1, 1))
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
	var style = btn.get_theme_stylebox("normal") as StyleBoxFlat

	if item:
		var meta = ItemDatabase.get_item(item.get_item_id())
		icon.text = meta.icon
		qty.text = str(item.qty) if item.qty > 1 else ""
		if title: title.text = ""

		# Update border color based on quality
		var q = item.quality
		if q == 1: style.border_color = Color(0.2, 0.8, 0.2, 1) # Green
		elif q == 2: style.border_color = Color(0.2, 0.5, 0.9, 1) # Blue
		elif q >= 3: style.border_color = Color(0.8, 0.2, 0.8, 1) # Purple
		else: style.border_color = Color(0.6, 0.6, 0.6, 1) # White/Gray

		# Inner glow for artifacts
		if meta.type == "artifact":
			style.bg_color = Color(0.3, 0.1, 0.1, 0.95)
		else:
			style.bg_color = Color(0.12, 0.1, 0.08, 0.95) if is_equip else Color(0.18, 0.15, 0.12, 0.8)

	else:
		icon.text = ""
		qty.text = ""
		style.border_color = Color(0.35, 0.28, 0.2, 1)
		style.bg_color = Color(0.12, 0.1, 0.08, 0.95) if is_equip else Color(0.18, 0.15, 0.12, 0.8)
		if title and is_equip:
			# Resets handled by not changing title if empty. But wait, if they unequip, we need to restore title.
			var names = ["⚔️ 武器", "🥋 法衣", "🛡️ 盾牌", "📿 法宝"]
			var idx = btn.get_index()
			if idx < names.size():
				title.text = names[idx]

# ==========================================
# 交互事件：Tooltip 悬停
# ==========================================
# ==========================================
# 交互事件：Tooltip 悬停
# ==========================================
func _on_bag_hover(idx: int):
	if not manager or manager.carried_item != null: return
	var item = inventory_comp.slots[idx]
	if item:
		var txt = _generate_tooltip(item)
		manager.show_tooltip(txt)

func _on_equip_hover(idx: int):
	if not manager or manager.carried_item != null: return
	var item = equipment_comp.slots[idx]
	if item:
		var txt = _generate_tooltip(item)
		manager.show_tooltip(txt)

func _generate_tooltip(item: ItemStack) -> String:
	var item_id = item.get_item_id()
	var meta = ItemDatabase.get_item(item_id)
	var type = meta.type
	var quality = item.quality
	var affixes = item.affixes

	var prefix = ""
	var color_hex = "#F0D050"
	if quality == 1: prefix = "【良品】"; color_hex = "#50F050"
	elif quality == 2: prefix = "【上品】"; color_hex = "#5050F0"
	elif quality >= 3: prefix = "【极品】"; color_hex = "#F050F0"

	var text = "[color=" + color_hex + "][b]" + prefix + (meta.name if meta.name != "" else item_id) + "[/b][/color]\n"
	text += "[color=#A0A0A0]" + str(meta.desc) + "[/color]\n"

	# 合并基础特效与动态词缀
	var effects = meta.get_effects().duplicate()
	for k in affixes:
		if typeof(affixes[k]) == TYPE_INT or typeof(affixes[k]) == TYPE_FLOAT:
			effects[k] = effects.get(k, 0) + affixes[k]
		else:
			effects[k] = affixes[k]

	if not effects.is_empty():
		text += "\n[color=#FFD700]-- 物品特效 --[/color]\n"
		for k in effects:
			var affix_str = ItemDatabase.get_affix_text(k, effects[k])
			if affix_str != "":
				text += affix_str + "\n"

	if type == "potion": text += "\n[color=#808080][右键使用] [1-9快捷栏]\n[Shift+右键] 戒指老爷爷洗练[/color]"
	elif type == "weapon": text += "\n[color=#808080][右键装备] [拖拽装备]\n[Shift+右键] 戒指老爷爷洗练[/color]"
	return text

# ==========================================
# 交互事件：左键拖拽、右键使用、数字键绑定
# ==========================================
func _on_bag_gui_input(event: InputEvent, idx: int):
	# 重度 DEBUG 打印
	if event is InputEventMouseButton:
		print("[DEBUG InventoryUI] _on_bag_gui_input | 槽位:", idx, " | pressed:", event.pressed, " | button:", event.button_index)

	if event is InputEventMouseButton and event.pressed:
		var data = inventory_comp.slots[idx]
		print("[DEBUG InventoryUI] 点击数据 data = ", data, " | carried_item = ", manager.carried_item)

		# 左键：拖拽交换
		if event.button_index == MOUSE_BUTTON_LEFT:
			if manager.carried_item == null:
				if data != null:
					print("[DEBUG InventoryUI] 左键抓起物品: ", data.get_item_id())
					manager.carried_item = data
					inventory_comp.clear_slot(idx)
			else:
				if data == null:
					print("[DEBUG InventoryUI] 左键放下物品: ", manager.carried_item.get_item_id())
					inventory_comp.set_slot(idx, manager.carried_item.get_item_id(), manager.carried_item.qty, {"affixes": manager.carried_item.affixes, "quality": manager.carried_item.quality})
					manager.carried_item = null
				else:
					if data.get_item_id() == manager.carried_item.get_item_id() and data.affixes.is_empty() and manager.carried_item.affixes.is_empty():
						print("[DEBUG InventoryUI] 左键合并物品: ", manager.carried_item.get_item_id())
						inventory_comp.set_slot(idx, data.get_item_id(), data.qty + manager.carried_item.qty)
						manager.carried_item = null
					else:
						print("[DEBUG InventoryUI] 左键交换物品: ", data.get_item_id(), " <-> ", manager.carried_item.get_item_id())
						var temp = data
						inventory_comp.set_slot(idx, manager.carried_item.get_item_id(), manager.carried_item.qty, {"affixes": manager.carried_item.affixes, "quality": manager.carried_item.quality})
						manager.carried_item = temp
			update_ui()
			manager.hide_tooltip()

		# 右键：弹出上下文菜单 (Context Menu) 或者 戒指老爷爷
		elif event.button_index == MOUSE_BUTTON_RIGHT and manager.carried_item == null:
			if data == null: return
			print("[DEBUG InventoryUI] 右键点击物品: ", data.get_item_id())

			if Input.is_key_pressed(KEY_SHIFT):
				_ring_grandpa_upgrade(idx, data)
				return

			# 弹出上下文菜单
			var ItemContextMenu = load("res://00070ui/player_hud/item_context_menu.gd")
			var menu = ItemContextMenu.new()
			menu.setup(idx, data, manager)
			menu.action_selected.connect(_on_context_menu_action)
			
			var root_hud = manager
			if root_hud:
				root_hud.add_child(menu)
				menu.global_position = get_global_mouse_position()

	# 1-9 快捷键绑定
	elif event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		if manager.carried_item == null:
			var data_slot = inventory_comp.slots[idx]
			if data_slot != null and hotbar_comp:
				var hotbar_idx = event.keycode - KEY_1
				print("[DEBUG InventoryUI] 快捷键绑定: ", data_slot.get_item_id(), " -> 槽位 ", hotbar_idx)
				hotbar_comp.set_slot(hotbar_idx, data_slot.get_item_id(), data_slot.qty, {"affixes": data_slot.affixes, "quality": data_slot.quality})
				manager.get_node("HotbarPanel").update_ui()
				manager.show_notification("已绑定到快捷栏 " + str(hotbar_idx + 1))
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()

func _on_context_menu_action(action_name: String, idx: int) -> void:
	var data = inventory_comp.slots[idx]
	if data == null: return
	
	var meta = ItemDatabase.get_item(data.get_item_id())
	var type = meta.type
	
	if action_name == "equip":
		print("[DEBUG InventoryUI] 上下文菜单装备: ", data.get_item_id())
		var old_equip = null
		if equipment_comp:
			# 简单处理：如果是武器就放 0，衣服放 1 (可以根据 type 判断更精细点)
			var target_slot = 0 if type == "weapon" else 1
			old_equip = equipment_comp.slots[target_slot]
			equipment_comp.set_slot(target_slot, data.get_item_id(), 1, {"affixes": data.affixes, "quality": data.quality})
			inventory_comp.set_slot(idx, null, 0)
			
			if old_equip:
				inventory_comp.set_slot(idx, old_equip.get_item_id(), 1, {"affixes": old_equip.affixes, "quality": old_equip.quality})
		update_ui()
	elif action_name == "use":
		print("[DEBUG InventoryUI] 上下文菜单消耗: ", data.get_item_id())
		var player = get_tree().get_first_node_in_group("player")
		if player and ItemEffectDispatcher.use_item(player, data):
			var ws = get_node_or_null("/root/WorldState")
			var is_test = ws and ws.get("test_mode")
			if not is_test and meta.uses != -1 and type != "artifact":
				inventory_comp.remove_item(data.get_item_id(), 1)
		update_ui()
		_on_bag_hover(idx)
	elif action_name == "drop":
		print("[DEBUG InventoryUI] 上下文菜单丢弃: ", data.get_item_id())
		# 在脚下生成 3D 物品... 暂时直接删除
		inventory_comp.remove_item(data.get_item_id(), data.qty)
		update_ui()

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
				var meta = ItemDatabase.get_item(manager.carried_item.get_item_id())
				var req_type = "weapon" if idx == 0 else "armor" # 简易校验
				if meta.type == req_type:
					if data == null:
						equipment_comp.set_slot(idx, manager.carried_item.get_item_id(), manager.carried_item.qty, {"affixes": manager.carried_item.affixes, "quality": manager.carried_item.quality})
						manager.carried_item = null
					else:
						var temp = data
						equipment_comp.set_slot(idx, manager.carried_item.get_item_id(), manager.carried_item.qty, {"affixes": manager.carried_item.affixes, "quality": manager.carried_item.quality})
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
					inventory_comp.set_slot(i, data.get_item_id(), data.qty, {"affixes": data.affixes, "quality": data.quality})
					equipment_comp.clear_slot(idx)
					update_ui()
					manager.hide_tooltip()
					return
			manager.show_notification("背包已满，无法卸下装备！")
		get_viewport().set_input_as_handled()

# ==========================================
# 金手指：戒指老爷爷系统 (万物升阶洗练)
# ==========================================
func _ring_grandpa_upgrade(idx: int, data: ItemStack) -> void:
	if manager: manager.show_notification("【戒指老爷爷】出手了！耗费本源，重塑造化！")

	var affixes = data.affixes
	var quality = data.quality

	# 提升品质
	quality += 1

	# 随机抽取一个词缀注入 (模拟 PoE 词缀池)
	var affix_pool = [
		{"key": "damage", "val": randi_range(10, 50)},
		{"key": "heal", "val": randi_range(20, 100)},
		{"key": "restore_mana", "val": randi_range(20, 100)},
		{"key": "lifesteal", "val": randi_range(5, 15)},
		{"key": "crit_chance", "val": randi_range(5, 20)}
	]

	var chosen = affix_pool[randi() % affix_pool.size()]
	affixes[chosen.key] = affixes.get(chosen.key, 0) + chosen.val

	# 重新写回槽位，使其成为不可堆叠的独立物品
	inventory_comp.set_slot(idx, data.get_item_id(), 1, {"affixes": affixes, "quality": quality})

	update_ui()
	_on_bag_hover(idx) # 刷新 Tooltip 展现特效
