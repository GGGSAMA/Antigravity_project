extends Node3D

func _ready() -> void:
	# 遍历自身所有子节点，自动寻找名字包含 floor 的模型组并禁用其物理碰撞
	# 避免影响我们手动铺设的真实地板碰撞体
	for child in get_children(true):
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
