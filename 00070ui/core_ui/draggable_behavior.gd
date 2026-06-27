extends Node
class_name DraggableBehavior

# 将这个脚本挂载为一个子节点，即可让它的父节点(Control)变成可拖拽的！

var target: Control
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@export var drag_margin: float = 30.0

func _ready() -> void:
	target = get_parent() as Control
	if target:
		# 连接父节点的 gui_input 信号
		target.gui_input.connect(_on_gui_input)
		# 确保父节点能响应鼠标事件
		if target.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			target.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_gui_input(event: InputEvent) -> void:
	if not target: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_pos = target.get_local_mouse_position()
				var title_bar_rect = Rect2(0, 0, target.size.x, 30)

				# 判断是否在顶部标题栏，或者四周边缘区域
				if title_bar_rect.has_point(local_pos) or (
					local_pos.x < drag_margin or local_pos.x > target.size.x - drag_margin or
					local_pos.y < drag_margin or local_pos.y > target.size.y - drag_margin
				):
					is_dragging = true
					drag_offset = target.get_global_mouse_position() - target.global_position
					# 提到最上层显示
					if target.get_parent():
						target.get_parent().move_child(target, -1)
					target.accept_event()
			else:
				is_dragging = false

	elif event is InputEventMouseMotion:
		if is_dragging:
			target.global_position = target.get_global_mouse_position() - drag_offset
			target.accept_event()
