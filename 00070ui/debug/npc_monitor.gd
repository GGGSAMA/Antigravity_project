extends "res://00070ui/core_ui/base_menu_ui.gd"
class_name NPCMonitorUI

var panel: PanelContainer
var dropdown: OptionButton
var label: RichTextLabel

var current_npc_id: String = ""
var show_all_diary: bool = false

func _ready() -> void:
	super._ready() # 隐藏
	z_index = 100 # Ensure it's on top
	
	if Engine.get_main_loop().root.has_node("EventBus"):
		Engine.get_main_loop().root.get_node("EventBus").npc_event_occurred.connect(_on_any_npc_event)
	
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.8, 0.4)
	panel.add_theme_stylebox_override("panel", style)
	
	# Size and center
	panel.custom_minimum_size = Vector2(600, 500)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	
	# 添加拖拽行为
	var dragger = Node.new()
	dragger.set_script(load("res://00070ui/core_ui/draggable_behavior.gd"))
	panel.add_child(dragger)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Top Bar
	var hbox = HBoxContainer.new()
	dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dropdown.item_selected.connect(_on_npc_selected)
	
	var refresh_btn = Button.new()
	refresh_btn.text = "刷新数据"
	refresh_btn.pressed.connect(refresh_ui)
	
	var close_btn = Button.new()
	close_btn.text = "关闭 [F4]"
	close_btn.pressed.connect(close_ui)
	
	hbox.add_child(dropdown)
	hbox.add_child(refresh_btn)
	hbox.add_child(close_btn)
	vbox.add_child(hbox)
	
	# Log Level Bar
	var log_hbox = HBoxContainer.new()
	var log_lbl = Label.new()
	log_lbl.text = "天道播报过滤:"
	
	var log_dropdown = OptionButton.new()
	log_dropdown.add_item("0-调试 (全部流水)")
	log_dropdown.add_item("1-日常 (买菜打工)")
	log_dropdown.add_item("2-重要 (机缘奇遇)")
	log_dropdown.add_item("3-纯净 (唯有天道)")
	log_dropdown.select(2) # Default IMPORTANT
	log_dropdown.item_selected.connect(_on_log_level_changed)
	
	var debug_diary_cb = CheckButton.new()
	debug_diary_cb.text = "履历调试模式"
	debug_diary_cb.toggled.connect(func(toggled_on): show_all_diary = toggled_on; refresh_ui())
	
	log_hbox.add_child(log_lbl)
	log_hbox.add_child(log_dropdown)
	log_hbox.add_child(debug_diary_cb)
	vbox.add_child(log_hbox)
	
	# Text Area
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	
	add_child(panel)
	visible = false

func toggle() -> void:
	if visible:
		close_ui()
	else:
		open_ui()

func open_ui() -> void:
	super.open_ui()
	populate_dropdown()
	refresh_ui()

# close_ui 会自动调用 super.close_ui()

func _on_any_npc_event(npc: CharacterData, event_id: String, ctx: Dictionary) -> void:
	if not visible: return
	if npc.npc_id == current_npc_id:
		refresh_ui()

func populate_dropdown() -> void:
	dropdown.clear()
	var sm = get_node_or_null("/root/SocialManager")
	if not sm:
		dropdown.add_item("SocialManager未加载")
		return
		
	var idx = 0
	for npc_id in sm.npc_attributes.keys():
		var data = sm.npc_attributes[npc_id]
		var n_name = "未知"
		if data is CharacterData:
			n_name = data.npc_name
		elif typeof(data) == TYPE_DICTIONARY:
			n_name = data.name
			
		dropdown.add_item(n_name + " [" + npc_id + "]")
		dropdown.set_item_metadata(idx, npc_id)
		
		# 保持之前的选中状态
		if npc_id == current_npc_id:
			dropdown.select(idx)
			
		idx += 1
		
	if dropdown.get_item_count() > 0 and current_npc_id == "":
		current_npc_id = dropdown.get_item_metadata(0)

func _on_log_level_changed(index: int) -> void:
	var ms = get_node_or_null("/root/MacroSimulator")
	if ms:
		ms.broadcast_level = index

func _on_npc_selected(index: int) -> void:
	current_npc_id = dropdown.get_item_metadata(index)
	refresh_ui()

func refresh_ui() -> void:
	if current_npc_id == "":
		label.text = "请选择一个 NPC"
		return
		
	var sm = get_node_or_null("/root/SocialManager")
	if not sm or not sm.npc_attributes.has(current_npc_id):
		label.text = "找不到该 NPC 的数据"
		return
		
	var data = sm.npc_attributes[current_npc_id]
	if not data is CharacterData:
		label.text = "该 NPC 的数据不是 CharacterData 对象，而是字典，说明注册逻辑仍有问题：\n" + str(data)
		return
		
	var t = "[b][color=cyan]NPC: %s[/color][/b] (ID: %s)\n" % [data.npc_name, data.npc_id]
	var exact_realm = data.cultivation_comp.get_realm_name() if data.cultivation_comp else "深不可测"
		
	var curr_qi = data.cultivation_comp.current_qi if data.cultivation_comp else 0.0
	var max_qi = data.cultivation_comp.max_qi_cache if data.cultivation_comp else 100.0
	t += "[color=purple]境界: %s[/color] (XP: %.1f / %.1f)\n" % [exact_realm, curr_qi, max_qi]
	t += "综合战力: %d\n" % data.combat_power
	t += "骨龄: %d / %d 岁\n" % [data.age, data.max_lifespan]
	t += "财富: %d 灵石\n" % data.money
	
	t += "名望(Fame): %d | 业力(Karma): %d\n" % [data.fame, data.karma]
	
	var fac_name = "散修"
	if data.faction: fac_name = data.faction.faction_name
	t += "宗门: %s (%s)\n\n" % [fac_name, data.faction_role]
	
	t += "[color=lightgreen]-- 灵根与资质 (Spiritual Roots) --[/color]\n"
	var roots = data.spiritual_roots
	t += "金: %d | 木: %d | 水: %d | 火: %d | 土: %d\n" % [roots.get("metal",0), roots.get("wood",0), roots.get("water",0), roots.get("fire",0), roots.get("earth",0)]
	
	# 判断灵根类型
	var root_count = 0
	for v in roots.values(): if v > 0: root_count += 1
	var root_name = "伪灵根"
	if root_count == 1: root_name = "天灵根"
	elif root_count == 2: root_name = "真灵根"
	elif root_count == 3: root_name = "三系杂灵根"
	elif root_count == 4: root_name = "四系杂灵根"
	t += "天赋体质: [color=yellow]%s[/color] (资质评级: %d)\n\n" % [root_name, data.aptitude]
	
	t += "[color=cyan]-- 基础属性 (Core Stats) --[/color]\n"
	t += "体力: %d | 灵力: %d | 悟性: %d\n" % [data.stamina, data.mana, data.comprehension]
	t += "速度: %d | 神识: %d | 心境: %d\n\n" % [data.speed, data.divine_sense, data.state_of_mind]
	
	t += "[color=orange]-- 生活职业 (Life Skills) --[/color]\n"
	var lvl_names = ["未知", "入门", "初级", "精通", "掌握", "大师"]
	var alch = data.life_skills["alchemy"]
	var smit = data.life_skills["smithing"]
	var tali = data.life_skills["talisman"]
	t += "炼丹: %s (XP: %.1f)\n" % [lvl_names[alch.level] if alch.level < 6 else "神级", alch.xp]
	t += "炼器: %s (XP: %.1f)\n" % [lvl_names[smit.level] if smit.level < 6 else "神级", smit.xp]
	t += "符箓: %s (XP: %.1f)\n\n" % [lvl_names[tali.level] if tali.level < 6 else "神级", tali.xp]
	
	var display_action_name = "未知"
	if Engine.get_main_loop().root.has_node("ActionLibrary"):
		display_action_name = Engine.get_main_loop().root.get_node("ActionLibrary").get_action_name(data.current_action)
	t += "[color=yellow]当前AI状态: %s (锁定 %d 天)[/color]\n\n" % [display_action_name, data.locked_days_remaining]
	
	t += "[color=lightblue]-- 效用需求 (Needs) --[/color]\n"
	t += "生存: %.1f | 修仙: %.1f | 财富: %.1f | 社交: %.1f\n\n" % [data.need_healing, data.need_cultivation, data.need_resource, data.need_status]
	
	if data.history_trajectory.size() > 0:
		t += "[color=gray]-- 近期履历 --[/color]\n"
		var start_idx = max(0, data.history_trajectory.size() - 15) # Show more entries
		for i in range(start_idx, data.history_trajectory.size()):
			var entry = data.history_trajectory[i]
			if typeof(entry) == TYPE_DICTIONARY:
				# 过滤：非调试模式下，只显示 milestone 或 2星(IMPORTANT) 及以上的事件
				if not show_all_diary:
					if entry.get("type", "routine") != "milestone" and entry.get("level", 1) < 2:
						continue
				
				var age_str = "[骨龄%d岁]" % entry.get("age", data.age)
				var text_str = entry.get("text", "")
				var lvl = entry.get("level", 1)
				var typ = entry.get("type", "routine")
				
				if typ == "milestone" or lvl >= 3:
					t += "[color=red]- %s %s[/color]\n" % [age_str, text_str]
				elif lvl == 2:
					t += "[color=yellow]- %s %s[/color]\n" % [age_str, text_str]
				else:
					t += "- %s %s\n" % [age_str, text_str]
			else:
				# 兼容旧存档的字符串
				if show_all_diary:
					t += "- " + str(entry) + "\n"
			
	label.text = t
