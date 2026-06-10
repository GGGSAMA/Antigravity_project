extends Node
# DialogueManager

var ui_instance: DialogueUI = null
var ui_scene = preload("res://ui/dialogue/dialogue_ui.tscn")

func _ready() -> void:
	# 确保UI层级最高
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_ui() -> DialogueUI:
	if not ui_instance:
		ui_instance = ui_scene.instantiate()
		# 必须同步添加到节点树，否则 @onready 变量还未初始化就会被调用，导致 null 报错
		get_tree().root.add_child(ui_instance)
	return ui_instance

func start_dialogue(npc: Node, speaker_name: String, text: String, options: Array) -> void:
	var ui = get_ui()
	ui.show_dialogue(npc, speaker_name, text, options)

func close_dialogue() -> void:
	if ui_instance:
		ui_instance.hide_dialogue()
