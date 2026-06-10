extends Node3D

@onready var building: Node3D = 

func _ready() -> void:
	if building:
		for child in building.get_children(true):
			if "floor" in child.name.to_lower() and "collisionfloor" not in child.name.to_lower():
				_disable_collisions_recursive(child)

func _disable_collisions_recursive(node: Node) -> void:
	if node is StaticBody3D:
		node.collision_layer = 0
		node.collision_mask = 0
	elif node is CollisionShape3D:
		node.disabled = true
	for child in node.get_children(true):
		_disable_collisions_recursive(child)
