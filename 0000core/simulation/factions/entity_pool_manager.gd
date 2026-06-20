extends Node

# ==============================================================================
# 实体对象池管理器 (EntityPoolManager)
# ==============================================================================
# 负责在内存中缓存实体(NPC、特效等)，极大地减少长时间跳跃后高频实例化带来的GC开销。

var _pool: Dictionary = {}

func _ready() -> void:
	print("[EntityPoolManager] 实体对象池系统启动...")

# 从池中获取或实例化一个新节点
func get_entity(scene_path: String) -> Node:
	if not _pool.has(scene_path):
		_pool[scene_path] = []
		
	var pool_array = _pool[scene_path]
	if pool_array.size() > 0:
		var node = pool_array.pop_back()
		if is_instance_valid(node):
			return node
			
	# 如果池子为空，则真正实例化
	var packed_scene = load(scene_path)
	if packed_scene:
		return packed_scene.instantiate()
	return null

# 将实体归还给池子，替代 queue_free()
func recycle_entity(scene_path: String, node: Node) -> void:
	if not is_instance_valid(node): return
	
	if node.get_parent():
		node.get_parent().remove_child(node)
		
	if not _pool.has(scene_path):
		_pool[scene_path] = []
		
	_pool[scene_path].append(node)
	
	# 如果池子太大，强制缩容
	if _pool[scene_path].size() > 100:
		var overflow = _pool[scene_path].pop_front()
		if is_instance_valid(overflow):
			overflow.queue_free()

# 强制清场（虚化开启时调用）
func recycle_all_in_group(group_name: String, scene_path: String) -> void:
	var nodes = get_tree().get_nodes_in_group(group_name)
	var count = 0
	for n in nodes:
		recycle_entity(scene_path, n)
		count += 1
	if count > 0:
		print("[EntityPoolManager] 强制回收了 %d 个活跃的 %s 节点到对象池中。" % [count, group_name])
