extends Node
class_name PlayerStateMachine

@export var initial_state: NodePath
@export var player: CharacterBody3D
@export var anim_node: Node

var current_state: PlayerState
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready

	if not player: player = owner as CharacterBody3D

	# 初始化所有子状态
	for child in get_children():
		if child is PlayerState:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.player = player
			child.anim_node = anim_node

	if initial_state:
		var initial = get_node(initial_state)
		if initial is PlayerState:
			current_state = initial
			current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)

func transition_to(state_name: String, msg: Dictionary = {}) -> void:
	var target = state_name.to_lower()
	if not states.has(target):
		push_error("PlayerStateMachine: No state named " + state_name)
		return

	if current_state:
		current_state.exit()

	current_state = states[target]
	current_state.enter(msg)

	if has_node("/root/Log"):
		get_node("/root/Log").debug("Combat", "Player State -> " + state_name)
