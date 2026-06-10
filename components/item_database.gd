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

# --- 安全加载机制：懒加载外部配置文件 ---
static func _load_if_empty() -> void:
	if not ITEMS.is_empty():
		return
		
	var path = "res://data/items.json"
	
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
		
	var json_text = file.get_as_text()
	file.close()
	
	# 3. 解析 JSON 数据并进行动态色值编译
	var raw_data = JSON.parse_string(json_text)
	if raw_data is Dictionary:
		for id in raw_data:
			var item_dict = raw_data[id] as Dictionary
			
			# 将 16 进制 HTML 颜色码动态编译为 Godot Color 对象，实现最高颜值背光渲染
			if item_dict.has("color") and item_dict["color"] is String:
				item_dict["color"] = Color.html(item_dict["color"])
			
			ITEMS[id] = item_dict
		print("【物品数据库】成功从外部 JSON 加载了 ", ITEMS.size(), " 个物品条目！")
	else:
		printerr("【物品数据库】JSON 语法解析失败。将启用内置兜底配置。")
		_load_fallback_items()

# --- 内置高还原度兜底物品数据（确保在文件读取异常时游戏永不崩溃） ---
static func _load_fallback_items() -> void:
	ITEMS = {
		"小还丹": {
			"icon": "🍶",
			"color": Color(0.24, 0.05, 0.07, 0.65), # 绛血红
			"desc": "以百年朱砂与太乙灵泉炼制而成的辟谷小还丹，置于温润玉瓷瓶中 (系统备用数据)",
			"effects": { "heal": 20 },
			"special_effects": { "heal": 40 }
		},
		"聚灵散": {
			"icon": "🍶",
			"color": Color(0.04, 0.16, 0.26, 0.65), # 灵海蓝
			"desc": "由聚灵草与玄清玉髓提炼而成的纯净聚灵散，置于碧青瓷瓶中 (系统备用数据)",
			"effects": { "restore_mana": 30 },
			"special_effects": { "restore_mana": 60 }
		},
		"五毒散": {
			"icon": "🏺",
			"color": Color(0.18, 0.04, 0.24, 0.65), # 妖魅紫
			"desc": "采五毒毒腺研磨而成的剧毒粉末，置于粗陶小罐中 (系统备用数据)",
			"effects": { "heal": -30 },
			"special_effects": { "poison_weapon": true }
		},
		"九转金丹": {
			"icon": "🌟",
			"color": Color(0.26, 0.22, 0.04, 0.65), # 灿金色
			"desc": "修仙界传闻中的至高神丹 (系统备用数据)",
			"effects": { "heal": 9999, "restore_mana": 9999 },
			"special_effects": { "heal": 9999, "restore_mana": 9999 }
		}
	}
	print("【物品数据库】已启用系统内置兜底物品配置！")

# --- 安全读取接口 API ---

# 获取某个物品的完整配置字典，若不存在则返回一个默认的空物品字典，防止游戏崩溃
static func get_item(item_id: String) -> Dictionary:
	_load_if_empty()
	if ITEMS.has(item_id):
		return ITEMS[item_id]
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
