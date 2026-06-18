extends Control
class_name DraggableUI

# 标记是否正在被拖拽
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@export var drag_margin: float = 20.0 # 边缘多宽的区域可以拖动

func _ready() -> void:
	# 确保 Control 可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 检查是否点击在边缘区域（顶部标题栏或四周边缘）
				# 这里简化为：只要点击在整个 Control 的上半部分 30 像素内，或者边缘 drag_margin 内，都可以拖拽
				var local_pos = get_local_mouse_position()
				var rect = Rect2(Vector2.ZERO, size)
				
				# 定义一个“可拖拽区域”：顶部 30 像素
				var title_bar_rect = Rect2(0, 0, size.x, 30)
				
				# 检查是否在标题栏，或者在整个界面的边缘
				if title_bar_rect.has_point(local_pos) or (
					local_pos.x < drag_margin or local_pos.x > size.x - drag_margin or
					local_pos.y < drag_margin or local_pos.y > size.y - drag_margin
				):
					is_dragging = true
					drag_offset = get_global_mouse_position() - global_position
					# 提到最上层
					get_parent().move_child(self, -1)
					accept_event()
			else:
				is_dragging = false
				
	elif event is InputEventMouseMotion:
		if is_dragging:
			global_position = get_global_mouse_position() - drag_offset
			accept_event()
