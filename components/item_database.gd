# ==============================================================================
# 【Godot 核心数据类：全局物品数据驱动数据库（ItemDatabase）】
# ------------------------------------------------------------------------------
# 类说明：从外部 data/items.json 动态加载所有物品的属性、图标、颜色、描述及效果。
#         提供极致的 MOD（模组）扩展支持与卓越的健壮性。
# ==============================================================================

extends Node
class_name ItemDatabase

# --- 运行时内存字典（动态加载的物品缓存） ---
static var ITEMS: Dictionary = {}

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
			
		return "[color=" + trans["color"] + "]" + trans["name"] + val_str + "[/color]"
	else:
		return "[color=#00FA9A]未知道纹: " + key + " (" + str(value) + ")[/color]"

# --- 安全加载机制：懒加载外部配置文件 ---
static func _load_if_empty() -> void:
	if not ITEMS.is_empty():
		return
		
	var path = "res://data/items.csv"
	
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
			
		var item_dict = {}
		var effects = {}
		var special_effects = {}
		var id = line[0]
		
		for i in range(1, headers.size()):
			var key = headers[i].strip_edges()
			var val = line[i].strip_edges()
			
			if val == "":
				continue
				
			# 自动类型推断转换
			var parsed_val = val
			if val.is_valid_int():
				parsed_val = val.to_int()
			elif val.is_valid_float():
				parsed_val = val.to_float()
			elif val.to_lower() == "true":
				parsed_val = true
			elif val.to_lower() == "false":
				parsed_val = false
				
			# 特殊字段解析路由
			if key == "color":
				item_dict["color"] = Color.html(val)
			elif key.begins_with("effect_"):
				effects[key.replace("effect_", "")] = parsed_val
			elif key.begins_with("special_"):
				special_effects[key.replace("special_", "")] = parsed_val
			else:
				item_dict[key] = parsed_val
				
		item_dict["effects"] = effects
		item_dict["special_effects"] = special_effects
		
		# 赋默认保底值
		if not item_dict.has("uses"): item_dict["uses"] = 1
		if not item_dict.has("is_catalyst"): item_dict["is_catalyst"] = false
		
		ITEMS[id] = item_dict
		
	file.close()
	print("【物品数据库】成功从外部 CSV 加载了 ", ITEMS.size(), " 个物品条目！")

# --- 内置高还原度兜底物品数据（确保在文件读取异常时游戏永不崩溃） ---
static func _load_fallback_items() -> void:
	ITEMS = {
		"小还丹": {
			"type": "consumable",
			"icon": "🍶",
			"color": Color(0.24, 0.05, 0.07, 0.65), # 绛血红
			"desc": "以百年朱砂与太乙灵泉炼制而成的辟谷小还丹，置于温润玉瓷瓶中 (系统备用数据)",
			"effects": { "heal": 20 },
			"special_effects": { "heal": 40 }
		},
		"聚灵散": {
			"type": "consumable",
			"icon": "🍶",
			"color": Color(0.04, 0.16, 0.26, 0.65), # 灵海蓝
			"desc": "由聚灵草与玄清玉髓提炼而成的纯净聚灵散，置于碧青瓷瓶中 (系统备用数据)",
			"effects": { "restore_mana": 30 },
			"special_effects": { "restore_mana": 60 }
		},
		"五毒散": {
			"type": "material",
			"icon": "🏺",
			"color": Color(0.18, 0.04, 0.24, 0.65), # 妖魅紫
			"desc": "采五毒毒腺研磨而成的剧毒粉末，置于粗陶小罐中 (系统备用数据)",
			"effects": { "heal": -30 },
			"special_effects": { "poison_weapon": true }
		},
		"千里传送令": {
			"type": "consumable",
			"icon": "📜",
			"color": Color(0.1, 0.6, 0.8, 0.65), # 空间蓝
			"desc": "刻有缩地成寸阵纹的玉符，捏碎后可瞬间挪移至高空或返回凡尘 (左键使用)。",
			"effects": { "mystic_realm_teleport": true },
			"special_effects": {}
		},
		"宗门传送令": {
			"type": "artifact",
			"icon": "令牌",
			"color": Color(0.8, 0.6, 0.1, 0.8), # 暗金
			"desc": "由宗门阵法孕育而成的核心信物，持有者可无视空间阻隔直接传送至宗门阵眼处。这是造物主的特权道具。",
			"effects": {}, # 动态通过 affixes 传入 teleport
			"special_effects": {}
		},
		"九转金丹": {
			"type": "consumable",
			"icon": "🌟",
			"color": Color(0.26, 0.22, 0.04, 0.65), # 灿金色
			"desc": "修仙界传闻中的至高神丹 (系统备用数据)",
			"effects": { "heal": 9999, "restore_mana": 9999 },
			"special_effects": { "heal": 9999, "restore_mana": 9999 }
		},
		"sect_foundation_token": {
			"type": "artifact",
			"icon": "🏛️",
			"color": Color(0.83, 0.68, 0.21, 0.8), # 金色
			"desc": "蕴含无上造化之力的开宗立派阵盘。使用后可于当前地块圈地建宗，演化宗门殿宇，招纳天下英才。",
			"effects": { "sect_foundation": true },
			"special_effects": {}
		}
	}
	print("【物品数据库】已启用系统内置兜底物品配置！")

# --- 安全读取接口 API ---

# 获取某个物品的完整配置字典，若不存在则返回一个默认的空物品字典，防止游戏崩溃
static func get_item(item_id: String) -> Dictionary:
	_load_if_empty()
	if ITEMS.has(item_id):
		var val = ITEMS[item_id]
		if val != null and typeof(val) == TYPE_DICTIONARY:
			return val
			
	return {
		"icon": "📦",
		"color": Color(0.1, 0.1, 0.1, 0.65),
		"desc": "未知散件物品。",
		"effects": {},
		"special_effects": {}
	}

# 快捷获取常规使用效果
static func get_effects(item_id: String) -> Dictionary:
	_load_if_empty()
	return get_item(item_id).get("effects", {})

# 快捷获取特殊战术使用效果
static func get_special_effects(item_id: String) -> Dictionary:
	_load_if_empty()
	return get_item(item_id).get("special_effects", {})
