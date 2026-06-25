extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var focus_owner = get_viewport().gui_get_focus_owner()
		var focus_name = focus_owner.name if focus_owner else "None"
		print("[InputDebug] 收到按键: ", OS.get_keycode_string(event.keycode), " | 当前 GUI 焦点: ", focus_name, " | 鼠标模式: ", Input.mouse_mode)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		print("[InputDebug] ⚠️ 按键未被任何 UI 拦截，进入底层 (Unhandled): ", OS.get_keycode_string(event.keycode))
