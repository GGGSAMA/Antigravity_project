extends Node
class_name GlobalMonsterManager

# ==============================================================================
# 全局怪兽管理器 (MonsterManager)
# ------------------------------------------------------------------------------
# 职责：
# 1. 集中管理全地图的 MonsterSpawner3D。
# 2. 距离剔除：当玩家离得太远时，冻结生成或回收实体，节省性能。
# 3. 统计全局存活怪物数量，提供调试接口。
# ==============================================================================

var spawners: Array = []
var active_distance: float = 150.0 # 激活距离（在这个范围内的Spawner才会生成实体）
var check_interval: float = 1.0
var _timer: float = 0.0

var player: Node3D = null

func _ready() -> void:
	print("[MonsterManager] 全局妖兽管理器已启动。")
	
func register_spawner(spawner: Node3D) -> void:
	if not spawners.has(spawner):
		spawners.append(spawner)

func unregister_spawner(spawner: Node3D) -> void:
	spawners.erase(spawner)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= check_interval:
		_timer = 0.0
		_update_spawners()

func _update_spawners() -> void:
	if not player:
		# 尝试获取玩家
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return
			
	var p_pos = player.global_position
	
	for spawner in spawners:
		var dist = spawner.global_position.distance_to(p_pos)
		if dist <= active_distance:
			if not spawner.is_active:
				spawner.activate()
		else:
			if spawner.is_active:
				spawner.deactivate()
