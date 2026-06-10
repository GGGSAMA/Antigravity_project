extends Node3D

const NPC_SCENE = preload("res://entities/npc/npc.tscn")
const FactionData = preload("res://core/simulation/factions/faction_data.gd")
const NPCData = preload("res://core/simulation/factions/npc_data.gd")

func _ready() -> void:
	print("[NPCSpawner] 开始生成测试修仙者...")
	spawn_test_npcs()

func spawn_test_npcs() -> void:
	# 宗门 A：蜀山剑派 (正道)
	var f1 = FactionData.new()
	f1.faction_name = "蜀山剑派"
	f1.alignment = 0
	
	# 宗门 B：万骨窟 (魔道)
	var f2 = FactionData.new()
	f2.faction_name = "万骨窟"
	f2.alignment = 1
	
	# 宗门 C：四海商会 (中立)
	var f3 = FactionData.new()
	f3.faction_name = "四海商会"
	f3.alignment = 2
	
	# 生成 NPC 1
	var n1_data = NPCData.new()
	n1_data.npc_name = "李逍遥"
	n1_data.faction = f1
	n1_data.cultivation_realm = 2 # 筑基期
	_instantiate_npc(n1_data, Vector3(5, 0.5, -5))
	
	# 生成 NPC 2
	var n2_data = NPCData.new()
	n2_data.npc_name = "血老怪"
	n2_data.faction = f2
	n2_data.cultivation_realm = 3 # 金丹期
	_instantiate_npc(n2_data, Vector3(-5, 0.5, -5))
	
	# 生成 NPC 3
	var n3_data = NPCData.new()
	n3_data.npc_name = "钱百万"
	n3_data.faction = f3
	n3_data.cultivation_realm = 1 # 炼气期
	_instantiate_npc(n3_data, Vector3(0, 0.5, -8))

func _instantiate_npc(data: NPCData, pos: Vector3) -> void:
	var npc_instance = NPC_SCENE.instantiate()
	npc_instance.data = data
	npc_instance.position = pos
	
	# 挂载到当前节点（比如世界根节点）
	add_child(npc_instance)
	print("[NPCSpawner] 生成 NPC: ", data.npc_name, " 隶属: ", data.faction.faction_name)
