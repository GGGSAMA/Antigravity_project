extends Control

var list_container: VBoxContainer
var right_slots_container: VBoxContainer
var selected_spell_id: String = ""

const SpellDatabase = preload("res://00020components/spell_database.gd")

func _init():
	set_anchors_preset(PRESET_FULL_RECT)

func _ready():
	var margin = MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# 左侧：已领悟法术列表
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_panel)
	
	var title1 = Label.new()
	title1.text = "【已领悟法术】"
	title1.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
	left_panel.add_child(title1)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(scroll)
	
	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)
	
	# 右侧：装备至轮盘
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_panel)
	
	var title2 = Label.new()
	title2.text = "【法术轮盘配置 (右手法术)】"
	title2.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
	right_panel.add_child(title2)
	
	right_slots_container = VBoxContainer.new()
	right_slots_container.add_theme_constant_override("separation", 10)
	right_panel.add_child(right_slots_container)
	
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_refresh_ui")

func _on_visibility_changed() -> void:
	if visible:
		_refresh_ui()

func _refresh_ui() -> void:
	for child in list_container.get_children():
		child.queue_free()
	for child in right_slots_container.get_children():
		child.queue_free()
		
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var spell_comp = player.get_node_or_null("Spells")
	if not spell_comp: return
	
	# 刷新列表
	for spell_id in spell_comp.unlocked_spells:
		var data = SpellDatabase.get_spell(spell_id)
		var lvl = spell_comp.get_spell_level(spell_id)
		var btn = Button.new()
		btn.text = data.get("icon", "") + " " + data.get("name", "Unknown") + " (Lv." + str(lvl) + ")"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Workaround for passing parameter to signal in Godot 4 without lambda captures issues in loop:
		btn.pressed.connect(_on_spell_selected.bind(spell_id))
		
		if spell_id == selected_spell_id:
			btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		list_container.add_child(btn)
		
	# 刷新右侧轮盘槽位
	for i in range(spell_comp.right_spells.size()):
		var s_id = spell_comp.right_spells[i]
		var data = SpellDatabase.get_spell(s_id) if s_id != "" else {}
		var slot_hbox = HBoxContainer.new()
		
		var lbl = Label.new()
		lbl.text = "槽位 " + str(i+1) + ": " + data.get("name", "空")
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_hbox.add_child(lbl)
		
		var equip_btn = Button.new()
		equip_btn.text = "装配"
		equip_btn.disabled = (selected_spell_id == "")
		equip_btn.pressed.connect(_equip_spell.bind(i, spell_comp))
		slot_hbox.add_child(equip_btn)
		
		right_slots_container.add_child(slot_hbox)

func _on_spell_selected(spell_id: String) -> void:
	selected_spell_id = spell_id
	_refresh_ui()

func _equip_spell(slot_index: int, spell_comp: Node) -> void:
	if selected_spell_id == "": return
	spell_comp.right_spells[slot_index] = selected_spell_id
	_refresh_ui()
