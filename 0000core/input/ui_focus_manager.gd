extends Node

# ==============================================================================
# 【全局 UI 栈管理器 (UIFocusManager / Stack Manager)】
# 职责：
# 采用栈(Stack)的形式管理全屏或模态交互型 UI。
# 只有栈底为空时，才释放鼠标控制权给玩家。
# ==============================================================================

signal ui_opened(ui_node: Control)
signal ui_closed(ui_node: Control)

# 维护当前打开的 UI 节点栈
var _ui_stack: Array[Control] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # 确保游戏暂停时也能响应

func pop_top_ui() -> void:
	if not _ui_stack.is_empty():
		# 强行关闭栈顶 UI
		var top_ui = _ui_stack.back()
		if top_ui and is_instance_valid(top_ui):
			if top_ui.has_method("close_ui"):
				top_ui.close_ui()
			else:
				top_ui.hide()
				pop_ui(top_ui)
		else:
			# 死节点防呆
			_ui_stack.pop_back()
			_update_mouse_mode()

# ==========================================
# 压栈与弹栈
# ==========================================
func push_ui(ui_node: Control) -> void:
	if not is_instance_valid(ui_node): return

	# 如果已经在栈里，先移除再放到栈顶
	if _ui_stack.has(ui_node):
		_ui_stack.erase(ui_node)

	_ui_stack.append(ui_node)

	# 监听该 UI 节点的 tree_exited，防止它意外被销毁导致死锁
	if not ui_node.tree_exited.is_connected(_on_ui_tree_exited.bind(ui_node)):
		ui_node.tree_exited.connect(_on_ui_tree_exited.bind(ui_node))

	print("[UIStack] Push UI:", ui_node.name, " Stack Size:", _ui_stack.size())
	ui_opened.emit(ui_node)
	_update_mouse_mode()

func pop_ui(ui_node: Control) -> void:
	if _ui_stack.has(ui_node):
		_ui_stack.erase(ui_node)
		if is_instance_valid(ui_node) and ui_node.tree_exited.is_connected(_on_ui_tree_exited.bind(ui_node)):
			ui_node.tree_exited.disconnect(_on_ui_tree_exited.bind(ui_node))

		print("[UIStack] Pop UI:", ui_node.name, " Stack Size:", _ui_stack.size())
		ui_closed.emit(ui_node)
		_update_mouse_mode()

func _on_ui_tree_exited(ui_node: Control) -> void:
	if _ui_stack.has(ui_node):
		print("[UIStack] [WARNING] UI Node destroyed while in stack:", ui_node)
		_ui_stack.erase(ui_node)
		_update_mouse_mode()

func _update_mouse_mode() -> void:
	for i in range(_ui_stack.size() - 1, -1, -1):
		if not is_instance_valid(_ui_stack[i]):
			_ui_stack.remove_at(i)

	var was_in_ui = Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	var in_ui = not _ui_stack.is_empty()
	
	if in_ui:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if was_in_ui != in_ui:
		if has_node("/root/EventBus"):
			get_node("/root/EventBus").ui_state_changed.emit(in_ui)

func is_in_ui() -> bool:
	return not _ui_stack.is_empty()

func force_close_all() -> void:
	for ui in _ui_stack:
		if is_instance_valid(ui):
			if ui.has_method("close_ui"):
				ui.close_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sys_toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# 全局优先拦截 ESC：不论哪个 UI 获取了焦点，只要在 UI 里，ESC 都能强行退栈
	if event.is_action_pressed("ui_cancel"):
		if is_in_ui():
			pop_top_ui()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if has_node("/root/Log"):
			get_node("/root/Log").ai_trace("Input", "key_press", {
				"keycode": OS.get_keycode_string(event.keycode),
				"ui_stack_size": _ui_stack.size()
			})
	elif event is InputEventMouseButton and event.pressed:
		if has_node("/root/Log"):
			get_node("/root/Log").ai_trace("Input", "mouse_click", {
				"button_index": event.button_index,
				"position_x": event.position.x,
				"position_y": event.position.y,
				"ui_stack_size": _ui_stack.size()
			})
