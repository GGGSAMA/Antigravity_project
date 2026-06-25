extends Node
class_name PopulationSpawner

const CharacterData = preload("res://0000core/simulation/character_data.gd")
const FactionData = preload("res://0000core/simulation/factions/faction_data.gd")
const LoreGenerator = preload("res://0000core/simulation/lore_generator.gd")

func generate_initial_population(faction: FactionData, creator_npc_id: String) -> void:
	var sm = get_node_or_null("/root/SocialManager")
	if not sm: return

	if creator_npc_id != "" and sm.npc_attributes.has(creator_npc_id):
		var creator: CharacterData = sm.npc_attributes[creator_npc_id]
		creator.faction_id = faction.faction_id
		creator.faction_role = "掌门"
		faction.members.append(creator_npc_id)
	else:
		_spawn_sect_member(faction, "掌门", 4) 

	for i in range(2):
		_spawn_sect_member(faction, "长老", 3) 

	for i in range(5):
		_spawn_sect_member(faction, "外门弟子", 1) 

func _spawn_sect_member(faction: FactionData, role: String, realm: int) -> void:
	var npc_id = "npc_" + str(Time.get_ticks_usec()) + str(randi() % 1000)
	var data = CharacterData.new()
	data.npc_id = npc_id
	data.npc_name = LoreGenerator.generate_npc_name() + " (" + role + ")"
	data.faction_id = faction.faction_id
	data.faction = faction
	data.faction_role = role
	data.cultivation_comp.cultivation_realm = realm
	data.current_location = str(faction.core_world_pos)

	# 强制执行阶级因果律灵根生成
	# 新架构：文明地缘机制下的灵根倾斜
	# 读取宗门的宗门建筑孵化规则或地缘属性
	var elements: Array[String] = []
	if faction:
		if faction.building and faction.building.spawn_rules.has("require_element"):
			elements.append(faction.building.spawn_rules["require_element"])
		elif faction.geo:
			elements.append(faction.geo.main_element)

	data.generate_roots_by_hierarchy(realm, elements, false)

	# 按照阶级分发财富与骨龄
	if realm >= 4: # 掌门/元婴
		data.age = randi_range(300, 800)
		data.money = randi_range(50000, 200000)
		data.stamina += 500
	elif realm == 3: # 长老/金丹
		data.age = randi_range(100, 300)
		data.money = randi_range(10000, 50000)
		data.stamina += 200
	elif realm == 2: # 内门/筑基
		data.age = randi_range(30, 80)
		data.money = randi_range(1000, 5000)
	else: # 外门/炼气
		data.age = randi_range(16, 25)
		data.money = randi_range(10, 500)

	var angle = randf() * TAU
	var radius = randf_range(3.0, 8.0) # 保证离中心阵眼柱(半径0.8)至少3米，避开物理穿模
	var offset_x = cos(angle) * radius
	var offset_z = sin(angle) * radius
	var spawn_pos = faction.core_world_pos + Vector3(offset_x, 0.5, offset_z)
	data.world_position = spawn_pos

	var sm = get_node_or_null("/root/SocialManager")
	if sm:
		var loot_allocator = sm.get_node_or_null("LootAllocator")
		if loot_allocator and loot_allocator.has_method("allocate_initial_loot"):
			loot_allocator.allocate_initial_loot(data)

		sm.npc_attributes[npc_id] = data

	faction.members.append(npc_id)

	# ==========================================
	# 纯数据态注册：禁止物理生成，直接推入后台池
	# ==========================================
	if Engine.get_main_loop().root.has_node("LODManager"):
		Engine.get_main_loop().root.get_node("LODManager").register_npc(data)
