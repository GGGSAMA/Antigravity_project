extends Node
# class_name ChronosScheduler (Will be Autoloaded as "ChronosScheduler")

# ==============================================================================
# 万物时序驱动总线中枢 (ChronosScheduler)
# ==============================================================================

# 5 个优先级梯队，对应 TimeNode.SettlePriority
var _priority_queues: Array = [[], [], [], [], []]

# ==============================================================================
# 长时序强制虚化开关 (Optimization 1)
# ==============================================================================
# 激活时，意味着全图正在进行高强度、大跨度的岁月推演。
# 此时会阻断一切 3D 实体生成，并将场景中多余的 NPC 强制回收，进入纯数学演算模式。
var is_macro_skipping: bool = false
signal macro_skip_started
signal macro_skip_ended

func _ready() -> void:
	print("[ChronosScheduler] 万物时序驱动引擎启动。正在倾听天道脉动...")
	if EventBus and EventBus.has_signal("level_changing"):
		EventBus.level_changing.connect(reset_state)

func reset_state() -> void:
	is_macro_skipping = false
	_priority_queues = [[], [], [], [], []]
	print("[ChronosScheduler] 状态已重置")

# 注册一个岁月节点
func register_node(node: TimeNode) -> void:
	var p = node.priority
	if p >= 0 and p < _priority_queues.size():
		if not _priority_queues[p].has(node):
			_priority_queues[p].append(node)

# 注销一个岁月节点
func unregister_node(node: TimeNode) -> void:
	var p = node.priority
	if p >= 0 and p < _priority_queues.size():
		_priority_queues[p].erase(node)

# 开启强制虚化推演
func begin_macro_skip() -> void:
	if is_macro_skipping: return
	is_macro_skipping = true
	print("[ChronosScheduler] 开启长时序强制虚化！全图实体屏蔽。")
	macro_skip_started.emit()

# 结束强制虚化推演
func end_macro_skip() -> void:
	if not is_macro_skipping: return
	is_macro_skipping = false
	print("[ChronosScheduler] 长时序推演结束！区块开始物理降临...")
	macro_skip_ended.emit()

# 核心：岁月大衍推算 (由 TimeManager 的协程按 chunk 调用)
func process_time_chunk(chunk_hours_passed: float) -> void:
	# 严格按照优先级链条进行结算
	for p_level in range(_priority_queues.size()):
		var queue = _priority_queues[p_level]

		# 倒序遍历防止在推演过程中有节点自我销毁导致迭代器失效
		for i in range(queue.size() - 1, -1, -1):
			var node = queue[i]
			if is_instance_valid(node):
				# 预留：如果在玩家极远处，可以选择不 process，而是累积到 hibernation_map 中
				node.process_time_chunk(chunk_hours_passed)
			else:
				# 清理已销毁节点
				queue.remove_at(i)
