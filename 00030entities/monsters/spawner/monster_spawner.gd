extends Node3D
class_name MonsterSpawner3D

# ==============================================================================
# 局部妖兽刷新点 (Monster Spawner)
# ------------------------------------------------------------------------------
# 职责：
# 1. 在关卡中定义刷新的区域、怪物类型和数量。
# 2. 接收全局管理器的调度（激活/冻结）。
# 3. 接收子物体（妖兽）死亡的通知，并启动重生计时器。
# ==============================================================================

@export var monster_id: String = "goblin_weak"
@export var max_count: int = 3
@export var spawn_radius: float = 10.0
@export var respawn_time: float = 10.0

var is_active: bool = false
var active_monsters: Array = []
var dead_count: int = 0

const MONSTER_SCENE = preload("res://00030entities/monsters/monster_base.tscn")

func _ready() -> void:
	# 隐形调试网格（可选，用于编辑器预览）
	# 向全局管理器注册
	if has_node("/root/MonsterManager"):
		get_node("/root/MonsterManager").register_spawner(self)

	# 某些情况下，如果全局管理器没起作用，自己先激活（兼容性）
	call_deferred("activate")

func _exit_tree() -> void:
	if has_node("/root/MonsterManager"):
		get_node("/root/MonsterManager").unregister_spawner(self)

func activate() -> void:
	if is_active: return
	is_active = true
	# 补充当前缺少的怪物
	_check_and_spawn()

func deactivate() -> void:
	if not is_active: return
	is_active = false
	# 如果想节省性能，这里可以保存存活怪物状态并 `queue_free()` 它们
	# 目前只停止生成。真正的深度冻结可以把 active_monsters 都释放掉。

func _check_and_spawn() -> void:
	if not is_active: return

	var needed = max_count - active_monsters.size() - dead_count
	for i in range(needed):
		_spawn_one_monster()

func _spawn_one_monster() -> void:
	var monster = MONSTER_SCENE.instantiate()
	monster.monster_id = monster_id
	monster.set("spawner", self) # 把自己的引用传给怪物

	# 随机圆盘内一个坐标
	var angle = randf() * TAU
	var r = sqrt(randf()) * spawn_radius
	var pos = global_position + Vector3(cos(angle) * r, 0, sin(angle) * r)

	monster.global_position = _get_ground_position(pos)

	# 挂载到当前节点下，或者世界根节点
	add_child(monster)
	active_monsters.append(monster)

func _get_ground_position(pos: Vector3) -> Vector3:
	# 优先尝试读取地形高度
	var terrain = null
	if Engine.get_main_loop().root:
		terrain = Engine.get_main_loop().root.find_child("Terrain3D", true, false)

	if terrain and "data" in terrain and terrain.data:
		var h = terrain.data.get_height(Vector3(pos.x, 0, pos.z))
		if not is_nan(h):
			return Vector3(pos.x, h + 0.5, pos.z)

	# 兜底向下射线
	var space_state = get_world_3d().direct_space_state
	var origin = Vector3(pos.x, pos.y + 100.0, pos.z)
	var end = Vector3(pos.x, pos.y - 100.0, pos.z)
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space_state.intersect_ray(query)
	if result:
		return result.position + Vector3(0, 0.5, 0)

	return Vector3(pos.x, pos.y + 0.5, pos.z)

func on_monster_died(monster: Node3D) -> void:
	active_monsters.erase(monster)
	dead_count += 1

	# 开启复活计时器
	var t = get_tree().create_timer(respawn_time)
	t.timeout.connect(_on_respawn_timeout)

func _on_respawn_timeout() -> void:
	if dead_count > 0:
		dead_count -= 1
		if is_active:
			_spawn_one_monster()
