extends Node3D

const NPC_SCENE = preload("res://entities/npc/npc.tscn")
const FactionData = preload("res://core/simulation/factions/faction_data.gd")
const NPCData = preload("res://core/simulation/factions/npc_data.gd")

func _ready() -> void:
	print("[NPCSpawner] 开始生成测试修仙者...")
	spawn_test_npcs()

func spawn_test_npcs() -> void:
	var spawn_points = [
		Vector3(510, 0.5, 5), # 李逍遥
		Vector3(500, 0.5, 5), # 血老怪
		Vector3(505, 0.5, 2)  # 钱百万
	]
	
	var test_ids = ["npc_li_xiaoyao", "npc_xue_laoguai", "npc_qian_baiwan"]
	
	for i in range(test_ids.size()):
		var npc_id = test_ids[i]
		if SocialManager.has_method("get_npc"):
			var attr = SocialManager.get_npc(npc_id)
			if attr.is_empty():
				continue
				
			var f_data = FactionData.new()
			f_data.faction_name = attr.get("faction_name", "无门无派")
			f_data.alignment = attr.get("alignment", 2)
			
			var n_data = NPCData.new()
			n_data.npc_name = attr.get("name", "无名散修")
			n_data.faction = f_data
			n_data.cultivation_realm = attr.get("cultivation", 1)
			
			_instantiate_npc(n_data, spawn_points[i])

func _instantiate_npc(data: NPCData, pos: Vector3) -> void:
	var npc_instance = NPC_SCENE.instantiate()
	npc_instance.data = data
	npc_instance.position = pos
	
	# 挂载到当前节点（比如世界根节点）
	add_child(npc_instance)
	print("[NPCSpawner] 生成 NPC: ", data.npc_name, " 隶属: ", data.faction.faction_name)
