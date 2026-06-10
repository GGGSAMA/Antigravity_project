extends Node
class_name CombatComponent

# ==============================================================================
# 【战斗系统组件 (CombatComponent) - 细节实现与调优基准】
# ------------------------------------------------------------------------------
# 牢大重点要求的“已调优细节前提”（绝对不可在重构中丢失的机制）：
# 1. 左右手按键映射机制：
#    - 鼠标左键 -> 对应左手模型动作 (trigger_left_swing)
#    - 鼠标右键 -> 对应右手模型动作 (trigger_right_swing)
# 2. 武器与空手施法逻辑分化：
#    - 装备武器时：右键挥砍武器（造成物理+力量加成伤害）；左键吃药或单手施法（左侧法术）。
#    - 空手状态时：双手皆可捏法诀施法！左键释放左侧设定的法术，右键释放右侧设定的法术。
# 3. 施法弹道偏置细节：
#    - 为了第一人称沉浸感，左侧法术生成时位置必须向左偏移 (offset_side = -0.16)
#    - 右侧法术生成时位置必须向右偏移 (offset_side = 0.16)
#    - 确保法术球看起来是从手掌中心发射出去的。
# ==============================================================================


@export var player: CharacterBody3D
@export var camera: Camera3D

func _ready() -> void:
	if not player: player = get_parent() as CharacterBody3D
	if player and not camera:
		var head = player.get_node_or_null("Head")
		if head: camera = head.get_node_or_null("Camera3D")

func handle_left_click() -> void:
	if not player: return
	
	# 触发第三人称全身动画
	var anim_comp = player.get_node_or_null("AnimationComponent")
	if anim_comp and anim_comp.has_method("play_attack"):
		anim_comp.play_attack()
	
	var equip = player.get("equipment_comp")
	var hotbar = player.get("hotbar_comp")
	var idx = player.get("active_hotbar_index")
	
	if not equip or not hotbar: return
	
	var has_weapon = equip.slots[0] != null
	var active_data = hotbar.slots[idx] if idx < hotbar.slots.size() else null
	
	if has_weapon:
		if active_data != null:
			_use_left_hand_potion()
		else:
			_execute_spell_cast(true)
	else:
		if active_data != null:
			if player.has_method("special_use_active_hotbar_item"):
				player.special_use_active_hotbar_item()
		else:
			_execute_spell_cast(true)

func handle_right_click() -> void:
	if not player: return
	
	var equip = player.get("equipment_comp")
	var hotbar = player.get("hotbar_comp")
	var idx = player.get("active_hotbar_index")
	
	if not equip or not hotbar: return
	
	var has_weapon = equip.slots[0] != null
	var active_data = hotbar.slots[idx] if idx < hotbar.slots.size() else null
	
	if has_weapon:
		_execute_weapon_attack()
	else:
		if active_data != null:
			if player.has_method("use_active_hotbar_item"):
				player.use_active_hotbar_item()
		else:
			_execute_spell_cast(false)

func _execute_weapon_attack() -> void:
	var vm = player.get("viewmodel")
	if vm: vm.trigger_right_swing()

	var spell_origin = camera.global_position if camera else player.global_position
	var forward_dir = -camera.global_transform.basis.z.normalized() if camera else -player.global_transform.basis.z.normalized()
	
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(spell_origin, spell_origin + forward_dir * 3.0)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("take_damage"):
		var dmg = randi_range(15, 25)
		var stats = player.get("stats")
		if stats:
			dmg += int(stats.get("strength") * 0.5)
		result.collider.take_damage(dmg, player.global_position)

func _use_left_hand_potion() -> void:
	var vm = player.get("viewmodel")
	if vm: vm.trigger_left_swing()
	if player.has_method("use_active_hotbar_item"):
		player.use_active_hotbar_item()

func _execute_spell_cast(is_left: bool) -> void:
	var spells = player.get("spells")
	if not spells: return
	
	var current_spell = spells.get_current_spell(is_left)
	if current_spell == null: return
	
	var vm = player.get("viewmodel")
	if is_left and vm:
		vm.trigger_left_swing()
	elif not is_left and vm:
		vm.trigger_right_swing()
		
	var stats = player.get("stats")
	if stats and stats.get("current_mana") < current_spell["cost"]:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("法力不足，无法施放！")
		return
		
	if stats:
		stats.set("current_mana", stats.get("current_mana") - current_spell["cost"])
		stats.mana_changed.emit(stats.get("current_mana"), stats.get("max_mana"))
		
	if player.has_method("_spawn_spell_projectile"):
		player._spawn_spell_projectile(current_spell, is_left)
