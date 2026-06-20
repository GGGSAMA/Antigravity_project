extends CharacterBody3D
class_name MonsterBase

# ==============================================================================
# 【妖兽基类 (MonsterBase)】
# ------------------------------------------------------------------------------
# 职责：提供统一的妖兽逻辑，包括：
# 1. 动态读取数据库初始化属性
# 2. 简易状态机（Idle / Chase / Attack）
# 3. 受击反馈与死亡掉落
# ==============================================================================

@export var monster_id: String = "goblin_weak"
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var monster_data: Dictionary = {}
var max_health: int = 50
var current_health: int = 50
var attack_damage: int = 5
var exp_yield: int = 10
var drop_table: Array = []

var target: Node3D = null
var is_dead: bool = false
var speed: float = 3.0
var spawner: Node3D = null

func _ready() -> void:
	# 确保我们在 NavigationServer 准备好之后再初始化
	await get_tree().physics_frame
	
	_init_from_database()
	
	# 如果没有挂载模型，动态加载占位符模型
	if get_node_or_null("Model") == null:
		var model_path = monster_data.get("model_path", "res://00083models/characters/gdquest_sophia/sophia_skin.tscn")
		var model_scene = load(model_path)
		if model_scene:
			var model = model_scene.instantiate()
			model.name = "Model"
			add_child(model)
			# 如果模型自带动画脚本，可以在这里设置一下状态
			if model.has_method("set_animation_state"):
				model.set_animation_state("idle")

func _init_from_database() -> void:
	var MonsterDatabase = load("res://00020components/monster_database.gd")
	if MonsterDatabase:
		monster_data = MonsterDatabase.get_monster(monster_id)
		max_health = monster_data.get("max_health", 50)
		current_health = max_health
		attack_damage = monster_data.get("attack_damage", 5)
		exp_yield = monster_data.get("exp_yield", 10)
		drop_table = monster_data.get("drop_table", [])
		self.name = monster_data.get("name", "妖兽")

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	# 简单的索敌：找 Player
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			
	if target:
		var dist = global_position.distance_to(target.global_position)
		if dist < 15.0 and dist > 1.5:
			# 追击
			nav_agent.target_position = target.global_position
			var next_pos = nav_agent.get_next_path_position()
			var dir = global_position.direction_to(next_pos)
			dir.y = 0
			dir = dir.normalized()
			
			velocity = dir * speed
			
			# 转向
			if dir.length_squared() > 0.01:
				var look_at_pos = global_position - dir
				look_at_pos.y = global_position.y
				look_at(look_at_pos, Vector3.UP)
				
			var model = get_node_or_null("Model")
			if model and model.has_method("set_animation_state"):
				model.set_animation_state("run")
				
		elif dist <= 1.5:
			# 攻击范围
			velocity = Vector3.ZERO
			var model = get_node_or_null("Model")
			if model and model.has_method("set_animation_state"):
				model.set_animation_state("attack")
				# 这里应该加入攻击 CD 和伤害结算
		else:
			# 发呆
			velocity = Vector3.ZERO
			var model = get_node_or_null("Model")
			if model and model.has_method("set_animation_state"):
				model.set_animation_state("idle")
				
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	move_and_slide()

func take_damage(amount: int, hit_pos: Vector3 = Vector3.ZERO) -> void:
	if is_dead: return
	
	current_health -= amount
	if has_node("/root/Log"):
		get_node("/root/Log").info("Combat", self.name + " 受到了 " + str(amount) + " 点伤害，剩余血量：" + str(current_health))
		
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	if has_node("/root/Log"):
		get_node("/root/Log").info("Combat", self.name + " 死亡。")
		
	# 播放死亡动画（临时用 idle 替代）或者变成尸体
	var model = get_node_or_null("Model")
	if model and model.has_method("set_animation_state"):
		model.set_animation_state("idle")
		
	# 通知所属刷新点
	if spawner and spawner.has_method("on_monster_died"):
		spawner.on_monster_died(self)
		
	# 掉落结算
	_process_drops()
	
	# 给玩家加经验
	if target and target.has_node("Stats"):
		# 假设有增加经验的方法
		pass
		
	# 倒下特效
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:x", -90.0, 0.5)
	tween.tween_callback(queue_free).set_delay(2.0)

func _process_drops() -> void:
	for drop in drop_table:
		if randf() <= drop.get("chance", 1.0):
			var qty = randi_range(drop.get("min_qty", 1), drop.get("max_qty", 1))
			if has_node("/root/Log"):
				get_node("/root/Log").info("Loot", self.name + " 掉落了 " + str(qty) + " 个 " + drop.get("item_id"))
			# 实体化掉落物或者直接进背包（简易实现先打日志）
