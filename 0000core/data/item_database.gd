# ==============================================================================
# 【Godot 核心数据类：全局物品数据驱动数据库（ItemDatabase）】
# ------------------------------------------------------------------------------
# 类说明：从外部 data/items.json 动态加载所有物品的属性、图标、颜色、描述及效果。
#         提供极致的 MOD（模组）扩展支持与卓越的健壮性。
# ==============================================================================

extends Node
class_name ItemDatabase

# --- 运行时内存字典（动态加载的物品缓存） ---
static var ITEMS: Dictionary[String, ItemData] = {}

# --- 词缀系统本地化映射表 (Affix Translation Dictionary) ---
const AFFIX_TRANSLATION = {
	"heal": {"name": "回复气血", "color": "#FF5050", "prefix": "+"},
	"restore_mana": {"name": "恢复灵力", "color": "#5050FF", "prefix": "+"},
	"damage": {"name": "额外攻击力", "color": "#FF3030", "prefix": "+"},
	"lifesteal": {"name": "吸血率(%)", "color": "#DC143C", "prefix": "+"},
	"crit_chance": {"name": "暴击率(%)", "color": "#FF8C00", "prefix": "+"},
	"mystic_realm_teleport": {"name": "附带特效: 破界穿梭", "color": "#DDA0DD", "prefix": ""},
	"poison_weapon": {"name": "武器淬毒", "color": "#32CD32", "prefix": ""},
	"sect_foundation": {"name": "开宗立派", "color": "#FFD700", "prefix": ""},
	"sect_name": {"name": "空间印记归属", "color": "#FFD700", "prefix": " - "},
	"teleport": {"name": "传送阵眼坐标", "color": "#DDA0DD", "prefix": ": "}
}

# 快捷获取格式化后的中文词缀描述
static func get_affix_text(key: String, value: Variant) -> String:
	if AFFIX_TRANSLATION.has(key):
		var trans = AFFIX_TRANSLATION[key]
		var val_str = ""
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			val_str = ": " + trans["prefix"] + str(value)
		elif typeof(value) == TYPE_BOOL and value == true:
			val_str = "" # bool 为 true 时只显示名字
		elif typeof(value) == TYPE_BOOL and value == false:
			return "" # bool 为 false 隐形
		elif typeof(value) == TYPE_STRING:
			val_str = trans["prefix"] + value
		elif typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_PACKED_VECTOR3_ARRAY:
			# 将数组转换为好看的字符串
			val_str = trans["prefix"] + str(value)

		return "[color=" + trans["color"] + "]" + trans.name + val_str + "[/color]"
	else:
		return "[color=#00FA9A]未知道纹: " + key + " (" + str(value) + ")[/color]"

# --- 安全加载机制：懒加载外部配置文件 ---
static func _load_if_empty() -> void:
	if not ITEMS.is_empty():
		return

	var path = "res://00050data/items.csv"

	# 1. 安全边界：校验文件是否存在
	if not FileAccess.file_exists(path):
		printerr("【物品数据库】配置文件未找到: ", path, "。将启用内置兜底配置。")
		_load_fallback_items()
		return

	# 2. 安全边界：校验文件是否可读
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("【物品数据库】配置文件无法读取: ", path, "。将启用内置兜底配置。")
		_load_fallback_items()
		return

	# 3. 解析 CSV 数据并动态重建 Effects/特殊效果字典
	var headers = file.get_csv_line()
	if headers.size() < 2:
		printerr("【物品数据库】CSV 表头异常。将启用内置兜底配置。")
		file.close()
		_load_fallback_items()
		return

	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < headers.size() or line[0] == "":
			continue

		var item = ItemData.new()
		var id = line[0]
		item.id = id

		for i in range(1, headers.size()):
			var key = headers[i].strip_edges()
			var val = line[i].strip_edges()

			if val == "":
				continue

			var parsed_val = val
			if val.is_valid_int():
				parsed_val = val.to_int()
			elif val.is_valid_float():
				parsed_val = val.to_float()
			elif val.to_lower() == "true":
				parsed_val = true
			elif val.to_lower() == "false":
				parsed_val = false

			if key == "name": item.name = val
			elif key == "icon": item.icon = val
			elif key == "color": item.color = val # Keep string, Godot UI uses Color.html later, or we parse if needed
			elif key == "desc": item.desc = val
			elif key == "type": item.type = val
			elif key == "uses": item.uses = parsed_val
			elif key == "is_catalyst": item.is_catalyst = parsed_val
			elif key == "price": item.price = parsed_val
			elif key == "effect_heal": item.effect_heal = parsed_val
			elif key == "effect_restore_mana": item.effect_restore_mana = parsed_val
			elif key == "effect_mystic_realm_teleport": item.effect_mystic_realm_teleport = parsed_val
			elif key == "effect_sect_foundation": item.effect_sect_foundation = parsed_val
			elif key == "special_heal": item.special_heal = parsed_val
			elif key == "special_restore_mana": item.special_restore_mana = parsed_val
			elif key == "special_poison_weapon": item.special_poison_weapon = parsed_val

		ITEMS[id] = item

	file.close()
	print("【物品数据库】成功从外部 CSV 加载了 ", ITEMS.size(), " 个物品条目！")

# --- 内置高还原度兜底物品数据（确保在文件读取异常时游戏永不崩溃） ---
static func _load_fallback_items() -> void:
	var add = func(id, type, icon, c, d, eh, sh, erm, srm):
		var it = ItemData.new()
		it.id = id; it.name = id; it.type = type; it.icon = icon; it.color = c; it.desc = d
		it.effect_heal = eh; it.special_heal = sh; it.effect_restore_mana = erm; it.special_restore_mana = srm
		ITEMS[id] = it
		
	add.call("青钢剑", "weapon", "🗡️", "#2e3c4b", "锋利的入门飞剑", 0, 0, 0, 0)
	
	var it_jin = ItemData.new()
	it_jin.id = "九转金丹"; it_jin.name = "九转金丹"; it_jin.type = "consumable"; it_jin.icon = "🌟"; it_jin.color = "#42380a"; it_jin.desc = "无上大药"
	it_jin.effect_heal = 9999
	it_jin.effect_restore_mana = 9999
	ITEMS["九转金丹"] = it_jin

	var it_tp = ItemData.new()
	it_tp.id = "千里传送令"; it_tp.name = "千里传送令"; it_tp.type = "consumable"; it_tp.icon = "📜"; it_tp.color = "#DDA0DD"; it_tp.desc = "进入秘境"
	it_tp.effect_mystic_realm_teleport = true
	ITEMS["千里传送令"] = it_tp

	var it_sect = ItemData.new()
	it_sect.id = "建宗阵盘"; it_sect.name = "建宗阵盘"; it_sect.type = "artifact"; it_sect.icon = "💠"; it_sect.color = "#FFD700"; it_sect.desc = "开宗立派"
	it_sect.effect_sect_foundation = true
	ITEMS["建宗阵盘"] = it_sect

	# 【法则级物品】
	var it_buff = ItemData.new()
	it_buff.id = "天工造物符"; it_buff.name = "天工造物符"; it_buff.type = "consumable"; it_buff.icon = "🧧"; it_buff.color = "#ff4500"; it_buff.desc = "使炼器效率翻倍"
	it_buff.effect_apply_buff = {"crafting_speed_mult": 2.0}
	ITEMS["天工造物符"] = it_buff

static func get_item(item_id: String) -> ItemData:
	_load_if_empty()
	if ITEMS.has(item_id):
		return ITEMS[item_id]

	var fallback = ItemData.new()
	fallback.id = item_id
	fallback.name = "未知物品"
	fallback.icon = "📦"
	fallback.color = "#1a1a1a"
	fallback.desc = "未知散件物品。"
	return fallback

# 快捷获取常规使用效果
static func get_effects(item_id: String) -> Dictionary:
	_load_if_empty()
	return get_item(item_id).get_effects()

# 快捷获取特殊战术使用效果
static func get_special_effects(item_id: String) -> Dictionary:
	_load_if_empty()
	return get_item(item_id).get_special_effects()
