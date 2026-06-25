extends CanvasLayer
class_name DialogueUI

@onready var speaker_label = $Control/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label = $Control/MarginContainer/VBoxContainer/TextLabel
@onready var options_container = $Control/MarginContainer2/OptionsContainer

var current_npc = null
var is_active = false

func _ready() -> void:
	visible = false

# 显示对话框
# options = [{"text": "闲聊", "action": "chat"}, ...]
func show_dialogue(npc: Node, speaker_name: String, text: String, options: Array) -> void:
	current_npc = npc
	speaker_label.text = speaker_name + "："
	text_label.text = text

	# 清除旧选项
	for child in options_container.get_children():
		child.queue_free()

	# 生成新选项
	var idx = 1
	for opt in options:
		var btn = Button.new()
		btn.text = str(idx) + ". " + opt["text"]
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# 样式覆盖：巫师3风格的金色悬停
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.0, 1.0)) # 金色
		btn.add_theme_color_override("font_focus_color", Color(1.0, 0.84, 0.0, 1.0))
		btn.add_theme_font_size_override("font_size", 24)

		# 绑定点击事件
		btn.pressed.connect(self._on_option_selected.bind(opt["action"]))

		# 鼠标悬停事件（可加入提示音）
		btn.mouse_entered.connect(func(): btn.grab_focus())

		options_container.add_child(btn)
		idx += 1

	visible = true
	is_active = true

	# 释放鼠标并阻止玩家控制镜头
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# 自动聚焦第一个选项
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

func hide_dialogue() -> void:
	visible = false
	is_active = false
	current_npc = null

	# 恢复鼠标控制
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_option_selected(action: String) -> void:
	if action == "leave":
		hide_dialogue()
	elif current_npc and current_npc.has_method("handle_dialogue_action"):
		current_npc.handle_dialogue_action(action)
	else:
		print("未处理的对话选项: ", action)
		hide_dialogue()
