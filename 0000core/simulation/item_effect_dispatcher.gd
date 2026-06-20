extends Node

# ==============================================================================
# 【修仙物品效果分发器 (ItemEffectDispatcher)】
# ------------------------------------------------------------------------------
# 核心职责：将 UI/操作层面的 "使用" 动作，解耦转发为真正的实体游戏逻辑。
# ==============================================================================

const ItemDatabase = preload("res://00020components/item_database.gd")

func _ready() -> void:
	print("[ItemEffectDispatcher] 物品效果解析引擎启动...")

# 使用物品入口
# 支持传入字符串 item_id 或者完整的 slot_data 字典
# 返回 bool: 是否成功消耗该物品
func use_item(user: Node, slot_data: Variant) -> bool:
	var item_id = ""
	var dynamic_affixes = {}

	print("[ItemEffectDispatcher] ======= 物品使用调试 =======")
	print("[ItemEffectDispatcher] slot_data type: ", typeof(slot_data), " value: ", slot_data)

	if typeof(slot_data) == TYPE_STRING:
		item_id = slot_data
	elif typeof(slot_data) == TYPE_DICTIONARY:
		item_id = slot_data.get("id", "")
		dynamic_affixes = slot_data.get("affixes", {})

	print("[ItemEffectDispatcher] item_id: ", item_id)
	print("[ItemEffectDispatcher] dynamic_affixes: ", dynamic_affixes)
		
	var meta = ItemDatabase.get_item(item_id)

	var base_effects = meta.get("effects", {})
	print("[ItemEffectDispatcher] base_effects: ", base_effects)

	# 合并基础特效与动态词缀
	var effects = base_effects.duplicate()
	for k in dynamic_affixes:
		if typeof(dynamic_affixes[k]) == TYPE_INT or typeof(dynamic_affixes[k]) == TYPE_FLOAT:
			effects[k] = effects.get(k, 0) + dynamic_affixes[k]
		else:
			effects[k] = dynamic_affixes[k]

	print("[ItemEffectDispatcher] merged effects: ", effects)
		
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
		
	if effects.has("sect_foundation"):
		_execute_sect_foundation(user)
		consumed = false # 不直接在这里消耗，等玩家放置阵眼成功后再消耗
		
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

func _log_trace(msg: String) -> void:
	var f = FileAccess.open("res://logs/game_full.log", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line("[%s] [ItemEffectDispatcher] %s" % [Time.get_time_string_from_system(), msg])
		f.close()
		
func _execute_teleport(user: Node, coords: Array) -> void:
	if not user is Node3D: return
	if coords.size() >= 3:
		var target_x = coords[0]
		var target_z = coords[2]
		_log_trace("Teleporting to: " + str(coords))
		
		# 1. 视线遮蔽与魔法过场 (隐藏高空传送的突兀感)
		var fade_canvas = CanvasLayer.new()
		fade_canvas.layer = 100
		var fade_rect = ColorRect.new()
		fade_rect.color = Color(0.05, 0.05, 0.1, 0) # 幽深的太玄黑色
		fade_rect.anchors_preset = Control.PRESET_FULL_RECT
		fade_canvas.add_child(fade_rect)
		
		var lbl = Label.new()
		lbl.text = "【缩地成寸，乾坤流转】\n重塑肉身中..."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 40)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		fade_rect.add_child(lbl)
		
		user.get_tree().current_scene.add_child(fade_canvas)
		
		var tween_in = user.get_tree().create_tween()
		tween_in.tween_property(fade_rect, "color", Color(0.05, 0.05, 0.1, 1.0), 0.2)
		await tween_in.finished
		
		# 2. 先传送到目标 XZ 的极高空，防止穿模并强制加载区块
		user.global_position = Vector3(target_x, 1000.0, target_z)
		_log_trace("Moved to sky (1000m)")
		
		if "velocity" in user:
			user.velocity = Vector3.ZERO
			
		# 暂停玩家物理更新，防止在这 1 秒内受到重力掉落
		user.set_physics_process(false)
		
		# 给 Terrain3D 和物理引擎 1 秒钟的时间加载目标区块的碰撞网格
		await user.get_tree().create_timer(1.0).timeout
		
		# 3. 现在区块碰撞应该已经加载，从 800 米高空向下发射射线
		# 因为玩家此时在 1000 米高空，射线从 800 米往下打，绝对不会打到玩家自己身上的飞剑和模型！
		var space = user.get_world_3d().direct_space_state
		var target_y = coords[1]
		if space:
			var query = PhysicsRayQueryParameters3D.create(
				Vector3(target_x, 800.0, target_z),
				Vector3(target_x, -200.0, target_z)
			)
			var result = space.intersect_ray(query)
			if not result.is_empty():
				target_y = result.position.y + 1.0 
				print("[ItemEffectDispatcher] 射线探测到真实表面: y=", target_y)
				_log_trace("Raycast hit! Final Y=" + str(target_y))
			else:
				var terrain = user.get_tree().root.find_child("Terrain3D", true, false)
				if terrain and "data" in terrain and terrain.data:
					var h = terrain.data.get_height(Vector3(target_x, 0, target_z))
					if not is_nan(h):
						target_y = h + 2.0
						_log_trace("Raycast missed. Used terrain.data: " + str(target_y))
					else:
						target_y = coords[1] + 2.0
						_log_trace("Raycast missed AND terrain.data returned NaN. Fallback to coords[1]: " + str(target_y))
				else:
					target_y = coords[1] + 2.0
					_log_trace("Raycast missed AND no terrain data. Fallback to coords[1]: " + str(target_y))
		
		user.global_position = Vector3(target_x, target_y, target_z)
		user.set_physics_process(true) # 恢复物理
		_log_trace("Teleport complete at: " + str(user.global_position))
		
		# 4. 淡出遮罩
		var tween_out = user.get_tree().create_tween()
		tween_out.tween_property(fade_rect, "color", Color(0.05, 0.05, 0.1, 0.0), 0.5)
		await tween_out.finished
		fade_canvas.queue_free()
		
		_notify_hud(user, "传送完毕！")
		print("[ItemEffectDispatcher] 执行传送完毕：最终位置=", user.global_position)

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

func _execute_sect_foundation(user: Node) -> void:
	if not user is Node3D: return
	var builder = user.get_node_or_null("SectBuilderComp")
	if not builder:
		builder = user.get_node_or_null("SectBuilder")
	if builder:
		builder.is_equipped = not builder.is_equipped
		
		# 支持无缝长按：一旦装备，立即根据鼠标当前物理状态判定是否按下
		if builder.is_equipped:
			builder.is_holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		else:
			builder.is_holding = false
			
		_notify_hud(user, "【开宗立派】阵盘已激活！右键长按地面以建宗！" if builder.is_equipped else "阵盘已收起。")
		if builder.prompt_label:
			builder.prompt_label.text = "Sect Builder: Hold Right Click to Build" if builder.is_equipped else "Sect Builder: Unequipped"
	else:
		_notify_hud(user, "无法展开建宗阵盘，缺乏宗门建造模块。")

# 辅助 UI 通知
func _notify_hud(user: Node, text: String) -> void:
	var hud = user.get_node_or_null("HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(text)
