extends Node
class_name SpiritMindAttr

const CharacterData = preload("res://0000core/simulation/character_data.gd")

var divine_sense: int = 10
var scan_radius: float = 10.0

func sync_from_resource(data: CharacterData) -> void:
	divine_sense = 10 + (data.cultivation_comp.cultivation_realm * 5)
	scan_radius = 5.0 + (divine_sense * 1.5)

func get_scan_radius() -> float:
	return scan_radius
