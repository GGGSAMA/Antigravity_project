extends Node

# ==============================================================================
# 【修仙物品效果分发器 (ItemEffectDispatcher)】
# ------------------------------------------------------------------------------
# 核心职责：将 UI/操作层面的 "使用" 动作，解耦转发为真正的实体游戏逻辑。
# ==============================================================================

const ItemDatabase = preload("res://components/item_database.gd")

func _ready() -> void:
	print("[ItemEffectDispatcher] 物品效果解析引擎启动...")

# 使用物品入口
# 支持传入字符串 item_id 或者完整的 slot_data 字典
# 返回 bool: 是否成功消耗该物品
func use_item(user: Node, slot_data: Variant) -> bool:
	var item_id = ""
	var dynamic_affixes = {}
	
	if typeof(slot_data) == TYPE_STRING:
		item_id = slot_data
	elif typeof(slot_data) == TYPE_DICTIONARY:
		item_id = slot_data.get("id", "")
		dynamic_affixes = slot_data.get("affixes", {})
		
	var meta = ItemDatabase.get_item(item_id)
	
	var base_effects = meta.get("effects", {})
	
	# 合并基础特效与动态词缀
	var effects = base_effects.duplicate()
	for k in dynamic_affixes:
		if typeof(dynamic_affixes[k]) == TYPE_INT or typeof(dynamic_affixes[k]) == TYPE_FLOAT:
			effects[k] = effects.get(k, 0) + dynamic_affixes[k]
		else:
			effects[k] = dynamic_affixes[k]
			
	if effects.is_empty():
		print("[ItemEffectDispatcher] 物品 " + item_id + " 无任何使用效果。")
		return false
		
	var consumed = false
	
	# 遍历执行所有效果
	if effects.has("heal"):
		_execute_heal(user, effects.heal)
		consumed = true
		
	if effects.has("restore_mana"):
		_execute_restore_mana(user, effects.restore_mana)
		consumed = true
		
	if effects.has("teleport"):
		_execute_teleport(user, effects.teleport)
		consumed = true
		
	if effects.has("mystic_realm_teleport"):
		_execute_mystic_realm_teleport(user)
		consumed = true
		
	return consumed

# ==============================================================================
# 具象化效果执行逻辑
# ==============================================================================

func _execute_heal(user: Node, amount: int) -> void:
	var stats = user.get_node_or_null("Stats")
	if stats and stats.has_method("heal"):
		stats.heal(amount)
		_notify_hud(user, "气血恢复: +" + str(amount))

func _execute_restore_mana(user: Node, amount: int) -> void:
	var stats = user.get_node_or_null("Stats")
	if stats and stats.has_method("restore_mana"):
		stats.restore_mana(amount)
		_notify_hud(user, "灵力恢复: +" + str(amount))

func _execute_teleport(user: Node, coords: Array) -> void:
	if not user is Node3D: return
	if coords.size() >= 3:
		var target_pos = Vector3(coords[0], coords[1], coords[2])
		user.global_position = target_pos
		_notify_hud(user, "空间扭曲，缩地成寸！")
		print("[ItemEffectDispatcher] 执行传送：", target_pos)

func _execute_mystic_realm_teleport(user: Node) -> void:
	if user == null: return
	var tree = user.get_tree()
	if tree == null: return
	
	var root = tree.current_scene
	if root != null and root.has_method("enter_mystic_realm"):
		if root.get("in_mystic_realm"):
			root.exit_mystic_realm()
			_notify_hud(user, "【千里传送令】灵光流转，重返凡尘！")
		else:
			root.enter_mystic_realm()
			_notify_hud(user, "【千里传送令】开启界门，遁入太玄洞天！")
		print("[ItemEffectDispatcher] 触发太玄洞天传送")

# 辅助 UI 通知
func _notify_hud(user: Node, text: String) -> void:
	var hud = user.get_node_or_null("HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(text)
