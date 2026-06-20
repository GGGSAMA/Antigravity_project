extends Node
class_name CombatComponent

# ==============================================================================
# 【战斗系统组件 (CombatComponent)】
# 职责：
# 挂载于 Player 下，专门接管和处理所有的战斗输入（左右键）、蓄力施法、武器挥砍、
# 以及法术弹道生成。它与 Inventory（物品）、Spells（法术书）和 ViewModel（第一人称手臂动画）高度耦合以实现战斗闭环。
#
# 架构规范：
# - Player 的 _unhandled_input 必须将左右键点击事件路由到此类的 handle_left_click / handle_right_click
# - 左侧法术位移偏移为 -0.16，右侧为 0.16，保持第一人称视觉沉浸感。
# ==============================================================================


@export var player: CharacterBody3D
@export var camera: Camera3D

var is_charging: bool = false
var charge_is_left: bool = false
var charge_is_item: bool = false
var current_action_data: Dictionary = {}
var charge_time_passed: float = 0.0
var charge_ready_flashed: bool = false
var continuous_cast_timer: float = 0.0

func _ready() -> void:
	if not player: player = get_parent() as CharacterBody3D
	if player and not camera:
		var head = player.get_node_or_null("Head")
		if head: camera = head.get_node_or_null("Camera3D")


func _process(delta: float) -> void:
	if is_charging:
		charge_time_passed += delta
		var total_time = current_action_data.get("cast_time", 1.0)
		var is_continuous = current_action_data.get("is_continuous", false)
		
		# Update UI
		var hud_manager = player.get_node_or_null("HUD")
		var main_hud = hud_manager.get_node_or_null("MainHUD") if hud_manager else null
		if main_hud and main_hud.has_method("update_cast_bar"):
			main_hud.update_cast_bar(charge_time_passed)
			
		if is_continuous:
			# 持续施法逻辑：按住不放时，每隔 cooldown 时间自动触发一次法术
			continuous_cast_timer += delta
			var cooldown = current_action_data.get("cooldown", 0.2)
			if continuous_cast_timer >= cooldown:
				var spell_comp = player.get_node_or_null("Spells")
				var stats = player.get("stats")
				var current_mana = stats.current_mana if stats else 100
				if spell_comp and spell_comp.can_cast(charge_is_left, current_mana):
					continuous_cast_timer -= cooldown
					_execute_spell_cast(charge_is_left, current_action_data)
				else:
					_release_charge()
		else:
			# 普通蓄力法术
			if charge_time_passed >= total_time and not charge_ready_flashed:
				charge_ready_flashed = true
				
				# 【接口1】触发蓄力完成音效
				_play_cast_ready_sfx(current_action_data)
				
				# 【接口2】触发蓄力完成特效 (这里暂时调用了 viewmodel 的手部发光闪烁)
				_play_cast_ready_vfx(charge_is_left, current_action_data)

# ------------------------------------------------------------------------------
# 处理玩家左键输入
# 优先级：快捷栏物品使用 > 武器物理挥砍 > 蓄力施展左手法术
# @param pressed: bool - true 为按下，false 为松开
# ------------------------------------------------------------------------------
func handle_left_click(pressed: bool = true) -> void:
	if not player: return
	
	if pressed:
		# 1. 优先检查快捷栏 (吃药/用法宝等)
		var hotbar = player.get("hotbar_comp")
		var active_item = null
		if hotbar and player.get("active_hotbar_index") != null:
			var idx = player.get("active_hotbar_index")
			if idx >= 0 and idx < hotbar.slots.size():
				active_item = hotbar.slots[idx]
		
		if active_item != null:
			# 有物品，根据物品决定是直接使用还是读条
			if player.has_method("use_active_hotbar_item"):
				player.use_active_hotbar_item()
				var vm = player.get("viewmodel")
				if vm and vm.has_method("trigger_left_swing"): 
					vm.trigger_left_swing()
			return
					
		# 2. 如果没有可用物品，检查是否有武器
		var equip_comp = player.get("equipment_comp")
		var weapon = equip_comp.slots[0] if equip_comp else null
		if weapon != null:
			# 有武器，挥砍物理攻击（挥剑气等）
			_execute_weapon_attack()
			return
	else:
		# 左键松开逻辑
		if is_charging and charge_is_left:
			_release_charge()

# ------------------------------------------------------------------------------
# 处理玩家右键输入
# 优先级：无论手中是否持有武器，均触发蓄力施展右手法术 (允许持剑施法)
# @param pressed: bool - true 为按下，false 为松开
# ------------------------------------------------------------------------------
func handle_right_click(pressed: bool = true) -> void:
	if not player: return
	
	if pressed:
		if has_node("/root/Log"):
			get_node("/root/Log").info("Combat", "右键按下，准备蓄力右手法术")
		# 右键捏诀施展右手法术
		_start_charge(false)
	else:
		if has_node("/root/Log"):
			get_node("/root/Log").info("Combat", "右键松开，判断是否结算施法")
		# 松开右键，结算施法（读条满则释放，未满则取消）
		if is_charging and not charge_is_left:
			_release_charge()

func _start_charge(is_left: bool) -> void:
	if is_charging: return
	
	if has_node("/root/Log"):
		get_node("/root/Log").debug("Combat", "尝试开始蓄力，is_left: " + str(is_left))
	
	var spell_comp = player.get_node_or_null("Spells")
	if not spell_comp:
		if has_node("/root/Log"):
			get_node("/root/Log").warn("Combat", "找不到 Spells 组件！")
		return
	
	current_action_data = spell_comp.get_active_spell(is_left)
	if current_action_data.is_empty():
		if has_node("/root/Log"):
			get_node("/root/Log").debug("Combat", "法术数据为空，尝试挥舞近战武器...")
		print("[Combat] 左/右键点击: 无可用法术或物品，执行空挥动作！")
		var vm = player.get("viewmodel")
		if vm:
			if is_left and vm.has_method("trigger_left_swing"):
				vm.trigger_left_swing()
			elif not is_left and vm.has_method("trigger_right_swing"):
				vm.trigger_right_swing()
		else:
			print("[Combat] 警告：玩家未挂载 ViewModel！由于您现在是第一人称，没有手部模型将无法看到挥砍动作！")
		return
	
	if has_node("/root/Log"):
		get_node("/root/Log").debug("Combat", "选定法术: " + current_action_data.get("name", "Unknown"))
	
	var stats = player.get("stats")
	var base_mana_cost = current_action_data.get("mana_cost", 0)
	var element = current_action_data.get("element", "fire")
	
	# 读取 CombatRuntimeAttr(alias: Stats) 缓存的减耗乘区，O(1)
	var mana_reduction = stats.get_multiplier(element + "_mana_reduction", 0.0) if stats and stats.has_method("get_multiplier") else 0.0
	var final_mana_cost = int(base_mana_cost * (1.0 - mana_reduction))
	
	var current_mana = stats.current_mana if stats else 100
	if not spell_comp.can_cast(is_left, current_mana):
		if has_node("/root/Log"):
			get_node("/root/Log").warn("Combat", "灵力不足！当前灵力: " + str(current_mana) + " 需要: " + str(final_mana_cost))
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("灵力不足！")
		return

	is_charging = true
	charge_is_left = is_left
	charge_time_passed = 0.0
	charge_ready_flashed = false
	
	var base_cooldown = current_action_data.get("cooldown", 0.2)
	var cd_reduction = stats.get_multiplier(element + "_cd_reduction", 0.0) if stats and stats.has_method("get_multiplier") else 0.0
	continuous_cast_timer = base_cooldown * (1.0 - cd_reduction)
	
	var vm = player.get("viewmodel")
	if vm and vm.has_method("start_casting_animation"):
		vm.start_casting_animation(is_left, current_action_data.get("color", Color(1,1,1)))
	
	var time_needed = current_action_data.get("cast_time", 1.0)
	var spell_name = current_action_data.get("name", "未知")
	if has_node("/root/Log"):
		get_node("/root/Log").info("Combat", "开始蓄力法术：" + spell_name + " 需要时间：" + str(time_needed))
		
	var hud_manager = player.get_node_or_null("HUD")
	var main_hud = hud_manager.get_node_or_null("MainHUD") if hud_manager else null
	if main_hud and main_hud.has_method("show_cast_bar"):
		if time_needed > 0.0:
			main_hud.show_cast_bar(time_needed, spell_name)

# ==========================================
# 【施法就绪提示接口】(VFX / SFX)
# ==========================================
func _play_cast_ready_sfx(spell_data: Dictionary) -> void:
	# 预留给音频管理器的接口：
	# var audio_manager = get_node_or_null("/root/AudioManager")
	# if audio_manager: audio_manager.play_sfx("spell_ready")
	if has_node("/root/Log"):
		get_node("/root/Log").debug("Combat", "【接口】播放蓄力完成音效：" + spell_data.get("name", ""))

func _play_cast_ready_vfx(is_left: bool, spell_data: Dictionary) -> void:
	# 目前暂时画的特效：让手部发光球猛烈闪烁一下
	var vm = player.get("viewmodel")
	if vm and vm.has_method("flash_cast_ready"):
		vm.flash_cast_ready(is_left)
	
	if has_node("/root/Log"):
		get_node("/root/Log").debug("Combat", "【接口】播放蓄力完成特效：" + spell_data.get("name", ""))

func _release_charge() -> void:
	if not is_charging: return
	
	var total_time = current_action_data.get("cast_time", 1.0)
	var is_continuous = current_action_data.get("is_continuous", false)
	
	if has_node("/root/Log"):
		get_node("/root/Log").info("Combat", "施法结算。已蓄力时间：" + str(charge_time_passed) + " / " + str(total_time))
	
	var vm = player.get("viewmodel")
	if vm and vm.has_method("stop_casting_animation"):
		vm.stop_casting_animation(charge_is_left)
	
	if not is_continuous:
		if charge_time_passed >= total_time:
			# 读条完毕，释放法术
			_execute_spell_cast(charge_is_left, current_action_data)
		else:
			# 读条未满，取消施法
			var hud_manager = player.get_node_or_null("HUD")
			if hud_manager and hud_manager.has_method("show_notification"):
				hud_manager.show_notification("施法被打断！")
			
	is_charging = false
	var hud_manager2 = player.get_node_or_null("HUD")
	var main_hud = hud_manager2.get_node_or_null("MainHUD") if hud_manager2 else null
	if main_hud and main_hud.has_method("hide_cast_bar"):
		main_hud.hide_cast_bar()

func _execute_weapon_attack() -> void:
	var vm = player.get("viewmodel")
	if vm: vm.trigger_right_swing() # 武器在右手，触发右手挥击

	var player_model = player.get_node_or_null("PlayerModel")
	if player_model:
		var anim_node = player_model.get_child(0) if player_model.get_child_count() > 0 else player_model
		if anim_node and anim_node.has_method("set_animation_state"):
			anim_node.set_animation_state("attack")

	# 新旧过渡兼容：如果不使用动画方法轨道，我们在这里开启一个延迟检测
	# 推荐做法是在 AnimationPlayer 中给 attack 动画打一根 Method Track，调用 apply_hitbox_damage()
	get_tree().create_timer(0.4).timeout.connect(apply_hitbox_damage)

func apply_hitbox_damage() -> void:
	if not player: return
	var spell_origin = camera.global_position if camera else player.global_position
	var forward_dir = -camera.global_transform.basis.z.normalized() if camera else -player.global_transform.basis.z.normalized()
	
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(spell_origin, spell_origin + forward_dir * 3.0)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("take_damage"):
		var dmg = randi_range(15, 25)
		
		# 读取动态词缀伤害加成
		var equip_comp = player.get("equipment_comp")
		var weapon = equip_comp.slots[0] if equip_comp else null
		if weapon != null:
			var affixes = weapon.get("affixes", {})
			dmg += affixes.get("damage", 0)
			
		var stats = player.get("stats")
		if stats:
			dmg += int(stats.get("strength") * 0.5)
			
		result.collider.take_damage(dmg, player.global_position)
		
		# 触发吸血等攻击特效
		if weapon != null and weapon.get("affixes", {}).has("lifesteal"):
			var ls = weapon.get("affixes", {}).get("lifesteal", 0)
			if ls > 0 and stats and stats.has_method("heal"):
				stats.heal(ls)
				var hud = player.get_node_or_null("HUD")
				if hud and hud.has_method("show_notification"):
					hud.show_notification("[吸血] 回复气血: +" + str(ls))

func _use_left_hand_potion() -> void:
	var vm = player.get("viewmodel")
	if vm: vm.trigger_left_swing()
	if player.has_method("use_active_hotbar_item"):
		player.use_active_hotbar_item()

func _execute_spell_cast(is_left: bool, spell_data: Dictionary) -> void:
	if spell_data.is_empty(): return
	
	var vm = player.get("viewmodel")
	var equip_comp = player.get("equipment_comp")
	var weapon = equip_comp.slots[0] if equip_comp else null
	var is_catalyst = false
	
	if weapon != null:
		var ItemDatabase = preload("res://00020components/item_database.gd")
		var meta = ItemDatabase.get_item(weapon.id)
		is_catalyst = meta.get("is_catalyst", false)
	
	if is_left and vm:
		# 左手法术
		vm.trigger_left_swing()
	elif not is_left and vm:
		# 右手法术，如果拿了可以施法的武器，则可能播放不同的动画（可选）
		# 暂用同样的动画
		vm.trigger_right_swing()
		
	var player_model = player.get_node_or_null("PlayerModel")
	if player_model:
		var anim_node = player_model.get_child(0) if player_model.get_child_count() > 0 else player_model
		if anim_node and anim_node.has_method("set_animation_state"):
			anim_node.set_animation_state("attack")
		
	var stats = player.get("stats")
	var base_mana_cost = spell_data.get("mana_cost", 10)
	var element = spell_data.get("element", "fire")
	
	var mana_reduction = stats.get_multiplier(element + "_mana_reduction", 0.0) if stats and stats.has_method("get_multiplier") else 0.0
	var final_mana_cost = int(base_mana_cost * (1.0 - mana_reduction))
	
	if stats:
		var current_mana = stats.get("current_mana")
		stats.set("current_mana", current_mana - final_mana_cost)
		stats.mana_changed.emit(stats.get("current_mana"), stats.get("max_mana"))
		
	if player.has_method("_spawn_spell_projectile"):
		# 传入法术数据，is_left 标志，以及 is_catalyst
		# 可以在 _spawn_spell_projectile 内部读取 cached_dmg_mults 给 projectile！
		spell_data["_cached_dmg_mult"] = stats.get_multiplier(element + "_dmg_mult", 1.0) if stats and stats.has_method("get_multiplier") else 1.0
		player._spawn_spell_projectile(spell_data, is_left)
