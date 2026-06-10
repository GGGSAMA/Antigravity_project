extends Node
class_name InteractionComponent

# ==============================================================================
# 【交互与神识扫描组件 (InteractionComponent)】
# ------------------------------------------------------------------------------
# 牢大（用户）需求档案：类似《无人深空》的 V键全息扫描与修仙神识威压
# 1. 扫描范围：半径由角色的 "divine_sense" (神识) 属性决定。
# 2. 灵力消耗：固定消耗 20 灵力。
# 3. 物品探知：高亮范围内的可交互物品/药草 (调用 highlight() 方法)。
# 4. 位阶威压：扫描波及敌人时，若自身神识 >= 敌人神识 + 5，
#    则形成降维打击的“威压”，强制敌人定身 4 秒 (调用 apply_stun() 或锁死 can_move)。
#
# 【AI 建议】：
# - 建议后续加入扫描特效：在世界坐标生成一个半透明的不断扩大的球体 Mesh。
# - 神识威压可以增加粒子特效（如敌人头顶冒出汗滴或眩晕符号）。
# ==============================================================================


@export var player: CharacterBody3D
@export var interaction_ray: RayCast3D
@export var combat_comp: Node

func _ready() -> void:
	if not player:
		player = get_parent() as CharacterBody3D
		print("[DEBUG] 动态获取 player: ", player)
	
	if not interaction_ray:
		interaction_ray = get_parent().get_node_or_null("Head/Camera3D/InteractionRay")
		print("[DEBUG] 动态获取 interaction_ray: ", interaction_ray)

	if not combat_comp:
		combat_comp = get_parent().get_node_or_null("CombatComponent")

	if player and interaction_ray:
		interaction_ray.add_exception(player)

func handle_interact_only() -> void:
	print("\n--- [DEBUG F键交互链路开始] ---")
	if not player: 
		print("[DEBUG] 失败：player 变量为空！")
		return
	if not interaction_ray:
		print("[DEBUG] 失败：interaction_ray 变量为空！")
		return
		
	print("[DEBUG] 射线目标点: ", interaction_ray.target_position)
	print("[DEBUG] 射线是否启用: ", interaction_ray.enabled)
	
	# 强制更新射线，确保物理状态最新
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		print("[DEBUG] 射线击中对象: ", collider.name, " 类型: ", collider.get_class())
		if collider.has_method("pick_up"):
			print("[DEBUG] 触发 pick_up()...")
			collider.pick_up(player)
		elif collider.has_method("interact"):
			print("[DEBUG] 目标包含 interact()，正在调用...")
			collider.interact(player)
		else:
			print("[DEBUG] 目标没有任何可交互的方法！")
	else:
		print("[DEBUG] 射线未能击中任何物体！")
		
	print("--- [DEBUG F键交互链路结束] ---\n")

func handle_interact_or_combat() -> void:
	if not player: return
	
	var picked_up_or_interacted := false
	if interaction_ray and interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider.has_method("pick_up"):
			collider.pick_up(player)
			picked_up_or_interacted = true
		elif collider.has_method("interact"):
			collider.interact(player)
			picked_up_or_interacted = true
			
	if not picked_up_or_interacted and combat_comp and combat_comp.has_method("handle_left_click"):
		combat_comp.handle_left_click()

func _physics_process(delta: float) -> void:
	if not player or not interaction_ray: return
	var stats = player.get("stats")
	if stats:
		var divine_sense = float(stats.get("divine_sense")) if stats.get("divine_sense") != null else 10.0
		# 强制把交互射线加长到 10 米，排除距离不够的问题
		interaction_ray.target_position = Vector3(0, 0, -10.0)

func _unhandled_input(event: InputEvent) -> void:
	# 神识全息扫描 (V 键)
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		execute_divine_scan()
		get_viewport().set_input_as_handled()
		
	# 实体交互 (F 键)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		print("[DEBUG] _unhandled_input 捕获到 F 键按下事件！")
		handle_interact_only()
		get_viewport().set_input_as_handled()

func execute_divine_scan() -> void:
	if not player: return
	var stats = player.get("stats")
	if not stats or not stats.has_method("consume_mana"): return
	
	# 每次扫描固定消耗 20 灵力
	if not stats.consume_mana(20):
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("灵力枯竭，无法展开神识！")
		return
		
	var divine_sense = float(stats.get("divine_sense")) if stats.get("divine_sense") != null else 10.0
	var radius = 5.0 + divine_sense * 1.5 # 神识越高，扫描半径越大
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("【神识展开】探测半径: " + str(snapped(radius, 0.1)) + " 米")
	
	# 执行球形物理查询
	var space_state = player.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = radius
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = player.global_transform
	# 排除静态地形，仅扫描动态物体（可配置 collision_mask，默认全扫）
	
	var results = space_state.intersect_shape(query)
	var enemies_stunned = 0
	var items_found = 0
	
	for res in results:
		var collider = res.collider
		if collider == player: continue
		
		# 1. 物品/药草高亮
		if collider.has_method("highlight") or collider.is_in_group("items"):
			if collider.has_method("highlight"):
				collider.highlight()
			items_found += 1
			
		# 2. 敌人神识威压 (定身)
		if collider.is_in_group("enemies") or collider.has_method("apply_stun") or collider.get("can_move") != null:
			var enemy_ds = 5.0 # 默认杂鱼神识极低
			if collider.get("stats") and collider.stats.get("divine_sense") != null:
				enemy_ds = float(collider.stats.get("divine_sense"))
				
			# 境界压制：自身神识必须大于敌人神识 5 点以上才能形成威压
			if divine_sense >= enemy_ds + 5.0:
				enemies_stunned += 1
				if collider.has_method("apply_stun"):
					collider.apply_stun(4.0) # 定身4秒
				else:
					# 简易保底控制：直接修改 can_move 属性并启动恢复计时器
					if collider.get("can_move") != null:
						collider.set("can_move", false)
						var timer = collider.get_tree().create_timer(4.0)
						timer.timeout.connect(func(): if is_instance_valid(collider): collider.set("can_move", true))
						
	# 扫描反馈输出
	print("神识扫描结束。发现物品: ", items_found, "，威压定身敌人: ", enemies_stunned)

