# ==============================================================================
# 【法术数据库 (SpellDatabase)】
# ------------------------------------------------------------------------------
# 类说明：从外部 data/spells.csv 动态加载所有法术的属性、图标、颜色、消耗及读条时间。
# ==============================================================================

extends Node
class_name SpellDatabase

# 运行时内存字典（缓存）
static var SPELLS: Dictionary[String, SpellData] = {}

static func get_spell(spell_id: String) -> SpellData:
	if SPELLS.is_empty():
		_load_spells()

	if SPELLS.has(spell_id):
		return SPELLS[spell_id]
	else:
		return _get_fallback_spell()

static func _load_spells() -> void:
	var path = "res://00050data/spells.csv"
	var file = FileAccess.open(path, FileAccess.READ)

	if not file:
		print("[SpellDatabase] 警告：找不到法术表 ", path, "，将使用内置数据。")
		_build_fallback_spells()
		return

	var header = file.get_csv_line()
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2 or line[0] == "":
			continue

		var id = line[0]
		var spell_data = SpellData.new()
		spell_data.id = id

		# 解析每一列
		for i in range(1, min(line.size(), header.size())):
			var key = header[i].strip_edges()
			var val_str = line[i].strip_edges()

			if val_str == "": continue

			# 数据类型转换尝试
			var parsed_val = val_str
			if val_str.is_valid_int():
				parsed_val = val_str.to_int()
			elif val_str.is_valid_float():
				parsed_val = val_str.to_float()
			elif val_str.to_lower() == "true":
				parsed_val = true
			elif val_str.to_lower() == "false":
				parsed_val = false

			if key == "name": spell_data.name = parsed_val
			elif key == "icon": spell_data.icon = parsed_val
			elif key == "color": spell_data.color = val_str
			elif key == "desc": spell_data.desc = str(parsed_val).replace("\\n", "\n")
			elif key == "mana_cost": spell_data.mana_cost = parsed_val
			elif key == "cast_time": spell_data.cast_time = parsed_val
			elif key == "cooldown": spell_data.cooldown = parsed_val
			elif key == "base_damage": spell_data.base_damage = parsed_val
			elif key == "effect_type": spell_data.effect_type = parsed_val
			elif key == "cast_range": spell_data.cast_range = parsed_val
			elif key == "aoe_radius": spell_data.aoe_radius = parsed_val
			elif key == "projectile_speed": spell_data.projectile_speed = parsed_val
			elif key == "is_continuous": spell_data.is_continuous = parsed_val

		SPELLS[id] = spell_data

	file.close()
	print("[SpellDatabase] 成功加载法术数据，共 ", SPELLS.size(), " 条。")

static func _build_fallback_spells() -> void:
	var add_spell = func(id, n, ic, c, mc, ct, cd, bd, et, cr, ar, ps, cont, d):
		var s = SpellData.new()
		s.id = id; s.name = n; s.icon = ic; s.color = c; s.mana_cost = mc; s.cast_time = ct; s.cooldown = cd; s.base_damage = bd; s.effect_type = et; s.cast_range = cr; s.aoe_radius = ar; s.projectile_speed = ps; s.is_continuous = cont; s.desc = d
		SPELLS[id] = s
		
	add_spell.call("spell_fireball", "火球术", "🔥", "#E6331A", 15, 1.0, 1.0, 35, "projectile", 25.0, 2.0, 18.0, false, "汇聚天地火元气，掷出一枚爆裂火球。")
	add_spell.call("spell_water", "水弹术", "💧", "#40E0D0", 8, 0.5, 0.5, 15, "projectile", 20.0, 1.0, 22.0, false, "凝水成弹，连绵不绝。")
	add_spell.call("spell_wind", "风刃术", "🌪️", "#40E640", 12, 0.8, 0.8, 25, "projectile", 30.0, 1.0, 28.0, false, "极速压缩风元素形成的锋锐气刃。")
	add_spell.call("spell_lightning", "掌心雷", "⚡", "#E6C040", 10, 0.0, 0.2, 10, "projectile", 15.0, 1.0, 40.0, true, "近战爆发，源源不断释放高压雷电。")
	add_spell.call("spell_ice", "冰锥术", "❄️", "#99E6FF", 20, 1.5, 2.0, 45, "projectile", 20.0, 1.0, 25.0, false, "凝结极寒冰锥，伤害极高。")
	add_spell.call("spell_earth", "岩突刺", "🪨", "#996633", 25, 2.0, 3.0, 60, "aoe", 15.0, 3.0, 0.0, false, "召唤大地之力。")
	add_spell.call("spell_heal", "回血术", "🌿", "#4DCC4D", 30, 2.5, 5.0, -50, "heal", 0.0, 0.0, 0.0, false, "大幅恢复自身气血。")
	add_spell.call("spell_meteor", "陨石术", "☄️", "#E64026", 50, 3.0, 8.0, 150, "projectile", 40.0, 6.0, 15.0, false, "大范围毁灭禁咒。")
	add_spell.call("spell_sword", "御剑诀", "⚔️", "#CCCCE6", 40, 2.0, 4.0, 80, "projectile", 35.0, 1.0, 50.0, false, "以气御剑，百步之外取敌首级。")
	add_spell.call("spell_shield", "真气盾", "🛡️", "#E6CC66", 35, 1.5, 10.0, 0, "buff", 0.0, 0.0, 0.0, false, "真气外放形成护体罡气。")

static func _get_fallback_spell() -> SpellData:
	var s = SpellData.new()
	s.id = "unknown"
	s.name = "未知法术"
	s.icon = "❓"
	s.color = "#808080"
	s.mana_cost = 10
	s.cast_time = 1.0
	s.cooldown = 1.0
	s.base_damage = 10
	s.effect_type = "projectile"
	s.cast_range = 20.0
	s.aoe_radius = 1.0
	s.projectile_speed = 15.0
	s.desc = "由于天地法则缺失，此法术无法被解析。"
	return s
