extends Control
class_name BaseMenuUI

# ==============================================================================
# 全局标准化菜单 UI 基类
# ==============================================================================

func _ready() -> void:
	# 确保初始状态下不遮挡鼠标（只有打开时才会拦截）
	visible = false

# 打开 UI 时调用
func open_ui() -> void:
	visible = true
	print("[BaseMenuUI] open_ui called for ", name)
	if has_node("/root/UIFocusManager"):
		get_node("/root/UIFocusManager").push_ui(self)

# 关闭 UI 时调用
func close_ui() -> void:
	visible = false
	print("[BaseMenuUI] close_ui called for ", name)
	if has_node("/root/UIFocusManager"):
		get_node("/root/UIFocusManager").pop_ui(self)

func _gui_input(event: InputEvent) -> void:
	pass
