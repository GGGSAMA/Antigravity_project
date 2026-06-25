extends Node
class_name InputBufferComponent

# ==============================================================================
# 【输入缓冲系统 (Input Buffer)】
# 职责：
# 拦截核心战斗与移动指令，将其压入队列并保留一段短暂的时间。
# 这样即使玩家在动画未结束前按下了攻击键，也能在“可取消帧/连击点”到来时完美衔接，
# 避免“狂按鼠标但角色没反应”的迟滞感。
# ==============================================================================

# 缓冲区保留时间 (秒)。魂系游戏通常在 0.3s - 0.5s 之间
@export var buffer_window: float = 0.4 

# 记录缓冲的指令及其时间戳
# 结构: {"action_name": "Attack_Left", "timestamp": 12345.67}
var _buffer: Array[Dictionary] = []

func _process(_delta: float) -> void:
	_cleanup_expired_inputs()

# 压入输入指令
func push_action(action_name: String) -> void:
	# 检查是否已存在同类指令，存在则更新时间戳
	for i in range(_buffer.size()):
		if _buffer[i]["action_name"] == action_name:
			_buffer[i]["timestamp"] = Time.get_ticks_msec() / 1000.0
			return

	# 新指令入队
	_buffer.append({
		"action_name": action_name,
		"timestamp": Time.get_ticks_msec() / 1000.0
	})

	if has_node("/root/Log"):
		get_node("/root/Log").debug("Input", "缓冲输入: " + action_name)

# 消费并获取优先级最高的有效输入
func consume_action(valid_actions: Array) -> String:
	_cleanup_expired_inputs()

	for action in valid_actions:
		for i in range(_buffer.size()):
			if _buffer[i]["action_name"] == action:
				# 找到匹配项，从缓冲区消耗掉它
				_buffer.remove_at(i)
				return action
	return ""

# 清理过期的输入
func _cleanup_expired_inputs() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var i = _buffer.size() - 1
	while i >= 0:
		if current_time - _buffer[i]["timestamp"] > buffer_window:
			_buffer.remove_at(i)
		i -= 1

# 清空缓冲区 (比如受击倒地时，之前的预输入全部作废)
func clear() -> void:
	_buffer.clear()
