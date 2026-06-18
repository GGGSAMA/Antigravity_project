extends Node

# ==============================================================================
# 【全局 UI 焦点仲裁者 (UIFocusManager)】
# 职责：
# 管理全屏或交互型 UI 面板的开关状态。
# 当有任何面板打开时，阻断底层 Player 的所有游戏行为输入（如攻击、建造、移动转向）。
# ==============================================================================

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

var _open_windows: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # 确保游戏暂停时也能响应

func is_gameplay_blocked() -> bool:
	return _open_windows.size() > 0

func open_ui(ui_name: String) -> void:
	if not _open_windows.has(ui_name):
		_open_windows.append(ui_name)
		print("[UIFocusManager] 打开了 UI:", ui_name, " 当前阻断状态:", is_gameplay_blocked())
		ui_opened.emit(ui_name)
		
		# 如果是第一个打开的 UI，释放鼠标
		if _open_windows.size() == 1:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_ui(ui_name: String) -> void:
	if _open_windows.has(ui_name):
		_open_windows.erase(ui_name)
		print("[UIFocusManager] 关闭了 UI:", ui_name, " 当前阻断状态:", is_gameplay_blocked())
		ui_closed.emit(ui_name)
		
		# 如果所有 UI 都关闭了，捕获鼠标
		if _open_windows.is_empty():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_ui(ui_name: String) -> bool:
	if _open_windows.has(ui_name):
		close_ui(ui_name)
		return false
	else:
		open_ui(ui_name)
		return true

func force_close_all() -> void:
	_open_windows.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("[UIFocusManager] 强制关闭所有 UI")
