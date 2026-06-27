extends Control

signal on_refine_started

@onready var btn_close = $MainLayout/LeftBook/BookVBox/TopBar/BtnReturn
@onready var btn_refine = $MainLayout/RightAction/BtnRefine
@onready var btn_study = $MainLayout/RightAction/BtnStudy

func _ready() -> void:
	var dragger = Node.new()
	dragger.set_script(load("res://00070ui/core_ui/draggable_behavior.gd"))
	add_child(dragger)

	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
	if btn_refine:
		btn_refine.pressed.connect(_on_refine_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()

func _on_close_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func _on_refine_pressed() -> void:
	on_refine_started.emit()
	_on_close_pressed()
