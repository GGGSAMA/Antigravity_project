class_name ItemEffectDispatcher
extends RefCounted

# ==============================================================================
# 【修仙物品法则指南 (ItemEffectDispatcher)】
# ------------------------------------------------------------------------------
# 核心职责：将 UI/操作层面的 "使用" 动作，解耦转发为真正的实体游戏逻辑。
# 设计架构：静态无状态类 (Static Stateless Class)
# 使用动态派发机制 (Dynamic Dispatch) 执行效果，支持任意扩展。
# ==============================================================================

const ItemDatabase = preload("res://0000core/000040_data/item_database.gd")

# 使用物品入口
static func use_item(user: Node, slot_data: Variant) -> bool:
	var item_id = ""
	var dynamic_affixes = {}

	if typeof(slot_data) == TYPE_STRING:
		item_id = slot_data
	elif typeof(slot_data) == TYPE_DICTIONARY:
		item_id = slot_data.get("id", "")
		dynamic_affixes = slot_data.get("affixes", {})
	elif typeof(slot_data) == TYPE_OBJECT:
		if slot_data.has_method("get_item_id"):
			item_id = slot_data.get_item_id()
		if "affixes" in slot_data:
			dynamic_affixes = slot_data.get("affixes")

	var meta = ItemDatabase.get_item(item_id)
	var base_effects = {}
	if meta != null:
		var eff = meta.get("effects")
		if eff != null:
			base_effects = eff

	# 合并基础特效与动态词缀
	var effects = base_effects.duplicate()
	for k in dynamic_affixes:
		if typeof(dynamic_affixes[k]) == TYPE_INT or typeof(dynamic_affixes[k]) == TYPE_FLOAT:
			effects[k] = effects.get(k, 0) + dynamic_affixes[k]
		else:
			effects[k] = dynamic_affixes[k]

	if effects.is_empty():
		return false

	var consumed = false

	# 核心：动态派发 (Dynamic Dispatch)
	# 通过遍历字典键，拼接出对应的函数名进行尝试调用
	for effect_key in effects.keys():
		var method_name = "_execute_" + effect_key
		var value = effects[effect_key]
		
		# 在 Godot 4 中，静态方法可以直接包装为 Callable
		var callable = Callable(ItemEffectDispatcher, method_name)
		if callable.is_valid():
			# 为了适配带参数和不带参数的函数
			# 我们统一规范：所有 _execute 函数如果带参数，要么只传 user，要么传 user 和 value
			# 这依赖于具体的函数定义，为了灵活，我们根据 effect_key 决定传参
			if effect_key in ["mystic_realm_teleport", "sect_foundation"]:
				callable.call(user)
			else:
				callable.call(user, value)
			consumed = true
		else:
			print("[ItemEffectDispatcher] 未知的天地法则 (方法未实现): ", method_name)

	# 特殊处理不消耗的情况
	if effects.has("sect_foundation"):
		consumed = false

	return consumed

# ==============================================================================
# 具象化效果执行逻辑 (所有扩展效果均写在此处)
# ==============================================================================

static func _execute_heal(user: Node, amount: int) -> void:
	var stats = user.get_node_or_null("Stats")
	if stats and stats.has_method("heal"):
		stats.heal(amount)
		_notify_hud(user, "气血恢复: +" + str(amount))

static func _execute_restore_mana(user: Node, amount: int) -> void:
	var stats = user.get_node_or_null("Stats")
	if stats and stats.has_method("restore_mana"):
		stats.restore_mana(amount)
		_notify_hud(user, "灵力恢复: +" + str(amount))

static func _execute_teleport(user: Node, coords: Array) -> void:
	if not user is Node3D: return
	if coords.size() >= 3:
		var target_x = coords[0]
		var target_y = coords[1]
		var target_z = coords[2]
		
		# 省略长代码，精简后的传送逻辑
		user.global_position = Vector3(target_x, target_y + 2.0, target_z)
		_notify_hud(user, "传送完毕！")

static func _execute_mystic_realm_teleport(user: Node) -> void:
	if user == null: return
	var tree = user.get_tree()
	if tree == null: return

	var root = tree.current_scene
	if root != null and root.has_method("enter_mystic_realm"):
		if root.get("in_mystic_realm"):
			root.exit_mystic_realm()
			_notify_hud(user, "【千里传送令】重返凡尘！")
		else:
			root.enter_mystic_realm()
			_notify_hud(user, "【千里传送令】开启太玄洞天！")

static func _execute_sect_name(user: Node, sect_name: String) -> void:
	# 宗门名字作为词缀时，仅作为展示用途或者配合 teleport 使用，无需单独执行逻辑。
	# 或者可以在 HUD 提示即将传送的宗门名称。
	_notify_hud(user, "即将传送到: " + sect_name)

static func _execute_sect_foundation(user: Node) -> void:
	if not user is Node3D: return
	var builder = user.get_node_or_null("SectBuilderComp")
	if not builder: builder = user.get_node_or_null("SectBuilder")
	if builder:
		builder.is_equipped = not builder.is_equipped
		_notify_hud(user, "【开宗立派】阵盘已激活！" if builder.is_equipped else "阵盘已收起。")
	else:
		_notify_hud(user, "无法展开建宗阵盘。")

# 【全新拓展机制：规则介入 Buff】
static func _execute_apply_buff(user: Node, buff_data: Dictionary) -> void:
	var stats = user.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")
	if not stats:
		stats = user.get_node_or_null("Stats")
		
	if stats and stats.has_method("add_modifier"):
		for key in buff_data:
			# 调用诸如 stats.add_modifier("crafting_speed_mult", 2.0, duration) 的接口
			stats.add_modifier(key, buff_data[key], 60.0) # 默认持续 60 秒
		_notify_hud(user, "获得天道法则加持！")
	else:
		print("[ItemEffectDispatcher] 用户缺少接收 Buff 的状态组件。")

# 辅助 UI 通知
static func _notify_hud(user: Node, text: String) -> void:
	var hud = user.get_node_or_null("HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(text)
