extends Node3D

const NPC_SCENE = preload("res://00030entities/npc/npc.tscn")
const FactionData = preload("res://0000core/000010_simulation/factions/faction_data.gd")
const CharacterData = preload("res://0000core/000010_simulation/entities/character_data.gd")

func _ready() -> void:
	add_to_group("npc_spawner")

func spawn_npc_dynamic(data: CharacterData, pos: Vector3) -> void:
	_instantiate_npc(data, pos)



func _log_trace(msg: String) -> void:
	var f = FileAccess.open("res://logs/game_full.log", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line("[%s] [NPCSpawner] %s" % [Time.get_time_string_from_system(), msg])
		f.close()

func _instantiate_npc(data: CharacterData, pos: Vector3) -> void:
	_log_trace("Instantiating NPC " + data.npc_name + " at pos: " + str(pos))
	var npc_instance = NPC_SCENE.instantiate()
	npc_instance.data = data
	if npc_instance.has_method("setup_from_data"):
		npc_instance.setup_from_data(data)

	# 优先使用真实地形高度 (避开物理碰撞未加载问题)
	var terrain = null
	if Engine.get_main_loop().root:
		terrain = Engine.get_main_loop().root.find_child("Terrain3D", true, false)

	if terrain and "data" in terrain and terrain.data:
		var h = terrain.data.get_height(Vector3(pos.x, 0, pos.z))
		if not is_nan(h):
			npc_instance.position = Vector3(pos.x, h + 0.2, pos.z)
			_log_trace("NPC pos set by terrain data: " + str(npc_instance.position))
		else:
			npc_instance.position = Vector3(pos.x, pos.y + 0.2, pos.z)
			_log_trace("NPC terrain data height was NaN! Used default: " + str(npc_instance.position))
	else:
		_log_trace("Terrain data unavailable. Trying Raycast.")
		# 强行修正 Y 轴：向地面打射线确保紧贴地形 (兜底)
		var space_state = get_world_3d().direct_space_state
		var origin = Vector3(pos.x, 200.0, pos.z) # 从高空 200 米处往下看
		var end = Vector3(pos.x, -100.0, pos.z)
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collision_mask = 1 # 仅与世界地形(Layer 1)碰撞，忽略NPC自身的碰撞体(避免堆叠飞天)
		var result = space_state.intersect_ray(query)

		if result:
			npc_instance.position = result.position + Vector3(0, 0.2, 0)
			_log_trace("NPC Raycast hit: " + str(npc_instance.position))
		else:
			npc_instance.position = Vector3(pos.x, pos.y + 0.2, pos.z)
			_log_trace("NPC Raycast missed. Defaulting to: " + str(npc_instance.position))

	# 挂载到当前节点（比如世界根节点）
	add_child(npc_instance)
	var fac_name = data.faction.faction_name if data.faction else "散修"
	print("[NPCSpawner] 生成 NPC: ", data.npc_name, " 隶属: ", fac_name, " 落点: ", npc_instance.position)
	_log_trace("Final NPC Position for " + data.npc_name + ": " + str(npc_instance.global_position))
