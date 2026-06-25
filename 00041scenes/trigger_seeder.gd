extends Node

func _ready() -> void:
	# 延迟一秒执行，确保 Terrain3D 完全加载
	call_deferred("_trigger_seeder")

func _trigger_seeder() -> void:
	var faction_manager = get_node_or_null("/root/FactionManager")
	if faction_manager and faction_manager.has_method("seed_initial_world"):
		print("[MapTrigger] 正在呼叫宗门播种机，基于当前地形撒下宗门！")
		faction_manager.seed_initial_world(5)
