extends Node
class_name TargetLockComponent

@export var camera: Camera3D
@export var player: CharacterBody3D
@export var lock_radius: float = 20.0

var locked_target: Node3D = null
var is_hard_locked: bool = false

func _ready() -> void:
	if not player: player = owner as CharacterBody3D
	if not camera and player:
		var head = player.get_node_or_null("Head")
		if head: camera = head.get_node_or_null("Camera3D")

func _process(delta: float) -> void:
	if is_hard_locked and is_instance_valid(locked_target):
		_update_camera_tracking(delta)
	elif not is_hard_locked:
		# 软锁定模式：高亮屏幕中央的敌人
		_update_soft_target()

func toggle_hard_lock() -> void:
	if is_hard_locked:
		is_hard_locked = false
		locked_target = null
		if has_node("/root/Log"):
			get_node("/root/Log").debug("Combat", "取消硬锁定")
	else:
		var target = _find_best_target()
		if target:
			locked_target = target
			is_hard_locked = true
			if has_node("/root/Log"):
				get_node("/root/Log").debug("Combat", "硬锁定目标: " + target.name)

func _find_best_target() -> Node3D:
	# 简单实现：找到距离最近且在视野前方的敌人
	var best_target = null
	var best_score = INF

	var sm = get_node_or_null("/root/SocialManager")
	if not sm: return null

	# 需要场景中实际的3D节点来做距离计算，这里假设有个Group
	var enemies = get_tree().get_nodes_in_group("npc")
	for enemy in enemies:
		if not enemy is Node3D: continue
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist < lock_radius:
			# 计算是否在前方
			var dir_to_enemy = (enemy.global_position - camera.global_position).normalized()
			var forward = -camera.global_transform.basis.z
			var dot = forward.dot(dir_to_enemy)

			if dot > 0.5: # 视野前方
				var score = dist - (dot * 5.0) # 综合距离和准星中心的得分
				if score < best_score:
					best_score = score
					best_target = enemy

	return best_target

func _update_soft_target() -> void:
	# 实时高亮瞄准的目标，不接管镜头
	var target = _find_best_target()
	if target != locked_target:
		locked_target = target
		# TODO: Notify UI to show target bracket

func _update_camera_tracking(delta: float) -> void:
	if not camera or not locked_target: return
	# 计算看向目标的旋转
	var target_pos = locked_target.global_position + Vector3(0, 1.0, 0) # 看向胸部
	var current_transform = camera.global_transform
	var target_transform = current_transform.looking_at(target_pos, Vector3.UP)

	# 平滑插值
	camera.global_transform = current_transform.interpolate_with(target_transform, 10.0 * delta)

	# 同步玩家身体朝向 (Yaw)
	var body_transform = player.global_transform
	var flat_target = Vector3(target_pos.x, body_transform.origin.y, target_pos.z)
	var body_target_transform = body_transform.looking_at(flat_target, Vector3.UP)
	player.global_transform = body_transform.interpolate_with(body_target_transform, 10.0 * delta)
