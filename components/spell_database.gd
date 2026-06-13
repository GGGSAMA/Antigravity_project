# ==============================================================================
# 【法术数据库 (SpellDatabase)】
# ------------------------------------------------------------------------------
# 类说明：从外部 data/spells.csv 动态加载所有法术的属性、图标、颜色、消耗及读条时间。
# ==============================================================================

extends Node
class_name SpellDatabase

# 运行时内存字典（缓存）
static var SPELLS: Dictionary = {}

static func get_spell(spell_id: String) -> Dictionary:
	if SPELLS.is_empty():
		_load_spells()
		
	if SPELLS.has(spell_id):
		return SPELLS[spell_id]
	else:
		return _get_fallback_spell()

static func _load_spells() -> void:
	var path = "res://data/spells.csv"
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
		var spell_data = {}
		
		# 解析每一列
		for i in range(1, min(line.size(), header.size())):
			var key = header[i]
			var val_str = line[i]
			
			# 数据类型转换尝试
			if val_str.is_valid_int():
				spell_data[key] = val_str.to_int()
			elif val_str.is_valid_float():
				spell_data[key] = val_str.to_float()
			elif val_str == "true" or val_str == "false":
				spell_data[key] = (val_str == "true")
			elif key == "color":
				spell_data[key] = Color(val_str) if val_str.begins_with("#") else Color(1, 1, 1)
			else:
				spell_data[key] = val_str.replace("\\n", "\n")
				
		SPELLS[id] = spell_data
		
	file.close()
	print("[SpellDatabase] 成功加载法术数据，共 ", SPELLS.size(), " 条。")

static func _build_fallback_spells() -> void:
	SPELLS["spell_fireball"] = {
		"name": "火球术", "icon": "🔥", "color": Color(0.9, 0.2, 0.1),
		"mana_cost": 15, "cast_time": 1.0, "cooldown": 1.0, "base_damage": 35, "effect_type": "projectile",
		"cast_range": 25.0, "aoe_radius": 2.0, "projectile_speed": 18.0, "is_continuous": false,
		"desc": "汇聚天地火元气，掷出一枚爆裂火球。"
	}
	SPELLS["spell_water"] = {
		"name": "水弹术", "icon": "💧", "color": Color(0.25, 0.88, 0.82),
		"mana_cost": 8, "cast_time": 0.5, "cooldown": 0.5, "base_damage": 15, "effect_type": "projectile",
		"cast_range": 20.0, "aoe_radius": 1.0, "projectile_speed": 22.0, "is_continuous": false,
		"desc": "凝水成弹，连绵不绝，消耗较低。"
	}
	SPELLS["spell_wind"] = {
		"name": "风刃术", "icon": "🌪️", "color": Color(0.25, 0.90, 0.25),
		"mana_cost": 12, "cast_time": 0.8, "cooldown": 0.8, "base_damage": 25, "effect_type": "projectile",
		"cast_range": 30.0, "aoe_radius": 1.0, "projectile_speed": 28.0, "is_continuous": false,
		"desc": "极速压缩风元素形成的锋锐气刃。"
	}
	SPELLS["spell_lightning"] = {
		"name": "掌心雷", "icon": "⚡", "color": Color(0.90, 0.75, 0.25),
		"mana_cost": 10, "cast_time": 0.0, "cooldown": 0.2, "base_damage": 10, "effect_type": "projectile",
		"cast_range": 15.0, "aoe_radius": 1.0, "projectile_speed": 40.0, "is_continuous": true,
		"desc": "近战爆发，按住可源源不断释放高压雷电。"
	}
	SPELLS["spell_ice"] = {
		"name": "冰锥术", "icon": "❄️", "color": Color(0.6, 0.9, 1.0),
		"mana_cost": 20, "cast_time": 1.5, "cooldown": 2.0, "base_damage": 45, "effect_type": "projectile",
		"cast_range": 20.0, "aoe_radius": 1.0, "projectile_speed": 25.0, "is_continuous": false,
		"desc": "凝结极寒冰锥，伤害极高且有几率冻结敌人。"
	}
	SPELLS["spell_earth"] = {
		"name": "岩突刺", "icon": "🪨", "color": Color(0.6, 0.4, 0.2),
		"mana_cost": 25, "cast_time": 2.0, "cooldown": 3.0, "base_damage": 60, "effect_type": "aoe",
		"cast_range": 15.0, "aoe_radius": 3.0, "projectile_speed": 0.0, "is_continuous": false,
		"desc": "召唤大地之力，在目标脚下突起锐利岩石。"
	}
	SPELLS["spell_heal"] = {
		"name": "回血术", "icon": "🌿", "color": Color(0.3, 0.8, 0.3),
		"mana_cost": 30, "cast_time": 2.5, "cooldown": 5.0, "base_damage": -50, "effect_type": "heal",
		"cast_range": 0.0, "aoe_radius": 0.0, "projectile_speed": 0.0, "is_continuous": false,
		"desc": "汲取草木生机，大幅恢复自身气血。"
	}
	SPELLS["spell_meteor"] = {
		"name": "陨石术", "icon": "☄️", "color": Color(0.9, 0.25, 0.15),
		"mana_cost": 50, "cast_time": 3.0, "cooldown": 8.0, "base_damage": 150, "effect_type": "projectile",
		"cast_range": 40.0, "aoe_radius": 6.0, "projectile_speed": 15.0, "is_continuous": false,
		"desc": "大范围毁灭禁咒，召唤天外陨石洗地。"
	}
	SPELLS["spell_sword"] = {
		"name": "御剑诀", "icon": "⚔️", "color": Color(0.8, 0.8, 0.9),
		"mana_cost": 40, "cast_time": 2.0, "cooldown": 4.0, "base_damage": 80, "effect_type": "projectile",
		"cast_range": 35.0, "aoe_radius": 1.0, "projectile_speed": 50.0, "is_continuous": false,
		"desc": "以气御剑，百步之外取敌首级，速度极快。"
	}
	SPELLS["spell_shield"] = {
		"name": "真气盾", "icon": "🛡️", "color": Color(0.9, 0.8, 0.4),
		"mana_cost": 35, "cast_time": 1.5, "cooldown": 10.0, "base_damage": 0, "effect_type": "buff",
		"cast_range": 0.0, "aoe_radius": 0.0, "projectile_speed": 0.0, "is_continuous": false,
		"desc": "真气外放形成护体罡气，大幅提升防御。"
	}

static func _get_fallback_spell() -> Dictionary:
	return {
		"name": "未知法术", "icon": "❓", "color": Color(0.5, 0.5, 0.5),
		"mana_cost": 10, "cast_time": 1.0, "cooldown": 1.0, "base_damage": 10, "effect_type": "projectile",
		"cast_range": 20.0, "aoe_radius": 1.0, "projectile_speed": 15.0, "is_continuous": false,
		"desc": "由于天地法则缺失，此法术无法被解析。"
	}
