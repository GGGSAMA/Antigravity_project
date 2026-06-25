extends Node
class_name PlayerState

var state_machine: PlayerStateMachine
var player: CharacterBody3D
var anim_node: Node

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass
