extends "res://0000core/ui/base_menu_ui.gd"
class_name ActionMenuUI

@onready var btn_meditate = $PanelContainer/VBoxContainer/BtnMeditate
@onready var btn_rest = $PanelContainer/VBoxContainer/BtnRest
@onready var btn_gather = $PanelContainer/VBoxContainer/BtnGather
@onready var btn_alchemy = $PanelContainer/VBoxContainer/BtnAlchemy
@onready var btn_forge = $PanelContainer/VBoxContainer/BtnForge

func _ready() -> void:
	visible = false
	btn_meditate.pressed.connect(_on_meditate_pressed)
	btn_rest.pressed.connect(_on_rest_pressed)
	if btn_gather:
		btn_gather.pressed.connect(_on_gather_pressed)
	if btn_alchemy:
		btn_alchemy.pressed.connect(_on_alchemy_pressed)
	if btn_forge:
		btn_forge.pressed.connect(_on_forge_pressed)

func open_ui() -> void:
	super.open_ui()

func close_ui() -> void:
	super.close_ui()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("sys_interact") and not event.is_echo():
		close_ui()
		get_viewport().set_input_as_handled()

func _on_meditate_pressed() -> void:
	close_ui()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").request_open_ui.emit("meditation")

func _on_rest_pressed() -> void:
	close_ui()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").show_notification.emit("你席地而坐，稍作歇息...")

func _on_gather_pressed() -> void:
	close_ui()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").show_notification.emit("开始寻找附近的灵草...")

func _on_alchemy_pressed() -> void:
	close_ui()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").request_open_ui.emit("alchemy")
		get_node("/root/EventBus").show_notification.emit("开启炼丹炉...(存根接口)")

func _on_forge_pressed() -> void:
	close_ui()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").request_open_ui.emit("forge")
		get_node("/root/EventBus").show_notification.emit("开启炼器炉...(存根接口)")
