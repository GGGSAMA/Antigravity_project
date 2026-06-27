extends Node

# ==============================================================================
# 实体分帧排队调度器 (SpawnQueueScheduler)
# ==============================================================================
# 负责在主线程 _process 中限制实体的实例化速率，防止由于大跨度跳跃结束或传送时导致的掉帧卡死。

const MAX_SPAWNS_PER_FRAME = 3

# 队列中存放字典: { "scene_path": String, "parent": Node, "data": CharacterData, "pos": Vector3, "priority": float }
var _spawn_queue: Array = []

func _ready() -> void:
	print("[SpawnQueueScheduler] 分帧排队生成系统已启动。")

	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		var chronos = Engine.get_main_loop().root.get_node("ChronosScheduler")
		chronos.macro_skip_started.connect(_on_macro_skip_started)

func _on_macro_skip_started() -> void:
	# 强行清空队列并回收场上现有的活跃NPC
	_spawn_queue.clear()
	if Engine.get_main_loop().root.has_node("EntityPoolManager"):
		var pool = Engine.get_main_loop().root.get_node("EntityPoolManager")
		# 假定NPC场景路径是这个，组名叫"NPC"
		pool.recycle_all_in_group("NPC", "res://00030entities/npc/npc.tscn")

# 提交一个生成请求
func request_spawn(scene_path: String, parent_node: Node, character_data: Resource, world_pos: Vector3, distance_to_player: float) -> void:
	if Engine.get_main_loop().root.has_node("ChronosScheduler") and Engine.get_main_loop().root.get_node("ChronosScheduler").is_macro_skipping:
		# 如果正在高强度跳时（虚化状态），拒绝任何生成请求，全部维持纯数据状态
		return

	var request = {
		"scene_path": scene_path,
		"parent": parent_node,
		"data": character_data,
		"pos": world_pos,
		"priority": distance_to_player # 距离越近优先级越高（数值越小越靠前）
	}
	_spawn_queue.append(request)

	# 按优先级(距离)排序
	_spawn_queue.sort_custom(func(a, b): return a["priority"] < b["priority"])

func _process(_delta: float) -> void:
	if _spawn_queue.is_empty():
		return

	if Engine.get_main_loop().root.has_node("ChronosScheduler") and Engine.get_main_loop().root.get_node("ChronosScheduler").is_macro_skipping:
		return # 虚化状态强行暂停生成处理

	var spawn_count = 0
	while not _spawn_queue.is_empty() and spawn_count < MAX_SPAWNS_PER_FRAME:
		var req = _spawn_queue.pop_front()
		if not is_instance_valid(req["parent"]): continue

		_execute_spawn(req)
		spawn_count += 1

func _execute_spawn(req: Dictionary) -> void:
	var node = null
	if Engine.get_main_loop().root.has_node("EntityPoolManager"):
		node = Engine.get_main_loop().root.get_node("EntityPoolManager").get_entity(req["scene_path"])
	else:
		var ps = load(req["scene_path"])
		if ps: node = ps.instantiate()

	if node:
		# 如果该节点拥有 setup_from_data 方法，强制数据单向注入！ (Optimization 3)
		if node.has_method("setup_from_data"):
			node.setup_from_data(req["data"])

		# 设置位置
		if node is Node3D:
			node.global_position = req["pos"]

		req["parent"].add_child(node)
