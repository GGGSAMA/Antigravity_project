extends Node

var active_factions: Dictionary = {}

func _ready() -> void:
	var brain_timer = Timer.new()
	brain_timer.wait_time = 10.0 
	brain_timer.autostart = true
	brain_timer.timeout.connect(_on_sect_brain_tick)
	add_child(brain_timer)
	
	# 自动延迟2秒后生成宗门（等场景和玩家完全加载好）
	var auto_seed_timer = Timer.new()
	auto_seed_timer.wait_time = 2.0
	auto_seed_timer.one_shot = true
	auto_seed_timer.autostart = true
	auto_seed_timer.timeout.connect(func(): 
		simulate_genesis()
		seed_initial_world(5)
	)
	add_child(auto_seed_timer)
	print("[FactionManager] 自动执行 Civilization-style 创世演化...")

# ==============================================================================
# 宏观创世管线 (Genesis Pipeline)
# Terrain Fake Data -> GeoAttr -> CultureAttr -> BuildingAttr
# ==============================================================================
func simulate_genesis() -> void:
	if has_node("/root/Log"):
		get_node("/root/Log").info("Genesis", "开始执行文明纪元地缘宗门生成流水线...")
		
	# 1. Fake Terrain Data (模拟 Terrain3D 传来的地块参数)
	var terrain_spots = [
		{"type": "volcano", "coord": Vector3(100, 0, 100)},
		{"type": "mountain_vein", "coord": Vector3(-200, 0, -50)},
		{"type": "swamp", "coord": Vector3(0, 0, 300)}
	]
	
	for i in range(terrain_spots.size()):
		var spot = terrain_spots[i]
		var sect = preload("res://core/simulation/factions/faction_data.gd").new()
		sect.faction_id = "sect_gen_" + str(i)
		
		# [阶段 A]: GeoAttr (地缘决定主属性)
		sect.geo.origin_terrain_type = spot["type"]
		if spot["type"] == "volcano":
			sect.faction_name = "焚天谷"
			sect.geo.main_element = "fire"
		elif spot["type"] == "mountain_vein":
			sect.faction_name = "金光剑派"
			sect.geo.main_element = "metal"
		elif spot["type"] == "swamp":
			sect.faction_name = "毒沼水阁"
			sect.geo.main_element = "water"
			
		# [阶段 B]: CultureAttr (主属性决定文化路线偏好)
		if sect.geo.main_element == "fire":
			sect.culture.alchemy_weight = 5.0
			sect.culture.global_buffs["alchemy_success_rate"] = 0.2
		elif sect.geo.main_element == "metal":
			sect.culture.sword_weight = 5.0
			sect.culture.global_buffs["sword_dmg_mult"] = 1.2
			
		# [阶段 C]: BuildingAttr (文化路线解锁宗门基建)
		sect.building.buildings["main_hall"] = 1
		if sect.culture.alchemy_weight >= 3.0:
			sect.building.buildings["alchemy_lab"] = 1
			sect.building.spawn_rules["require_element"] = "fire"
		if sect.culture.sword_weight >= 3.0:
			sect.building.buildings["sword_forge"] = 1
			sect.building.spawn_rules["require_element"] = "metal"
			
		# [阶段 D]: PowerAttr (注入国力池，准备推演)
		sect.power.resource_reserves = 5000
		sect.power.max_population = 100
		
		# 存入全局字典
		active_factions[sect.faction_id] = sect
		
		# 打印管线日志验证
		var log_msg = "孵化 [%s]: 地形=%s | 主属性=%s | 偏向=炼丹(%.1f)/剑修(%.1f) | 解锁建筑=%s" % [
			sect.faction_name, sect.geo.origin_terrain_type, sect.geo.main_element,
			sect.culture.alchemy_weight, sect.culture.sword_weight,
			str(sect.building.buildings.keys())
		]
		print("[Genesis Pipeline] ", log_msg)
		if has_node("/root/Log"):
			get_node("/root/Log").debug("Genesis", log_msg)

func create_sect_at_location(world_pos: Vector3, creator_npc_id: String = "") -> String:
	var generator = get_node_or_null("SectGenerator")
	if generator and generator.has_method("create_sect_at_location"):
		return generator.create_sect_at_location(world_pos, creator_npc_id)
	return ""

func seed_initial_world(sect_count: int = 5) -> void:
	var seeder = get_node_or_null("WorldSectSeeder")
	if seeder and seeder.has_method("seed_initial_sects"):
		seeder.seed_initial_sects(sect_count)

func _on_sect_brain_tick() -> void:
	var brain = get_node_or_null("SectBrainAI")
	if brain and brain.has_method("evaluate_needs_and_dispatch_tasks"):
		for sect_id in active_factions:
			var faction = active_factions[sect_id]
			brain.evaluate_needs_and_dispatch_tasks(faction)
