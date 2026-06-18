extends Node
class_name NPCGenerator

const CharacterData = preload("res://core/simulation/character_data.gd")

func generate_test_data() -> void:
	var sm = get_parent() # SocialManager
	
	# 1. 注册李逍遥
	_register_npc(sm, "npc_li_xiaoyao", {
		"name": "李逍遥",
		"faction_name": "蜀山剑派",
		"alignment": 0, # 正道
		"cultivation": 1, # 炼气
		"personality_tags": ["嫉恶如仇", "剑痴"],
		"status": "游历中",
		"wealth": 500,
		"age": 50,
		"max_lifespan": 100,
		"combat_power": 15
	})
	
	# 2. 注册血老怪
	_register_npc(sm, "npc_xue_laoguai", {
		"name": "血老怪",
		"faction_name": "万骨窟",
		"alignment": 1, # 魔道
		"cultivation": 3, # 金丹
		"personality_tags": ["残暴", "护短", "极度贪婪"],
		"status": "疗伤中",
		"wealth": 8000
	})
	
	# 3. 注册钱百万
	_register_npc(sm, "npc_qian_baiwan", {
		"name": "钱百万",
		"faction_name": "四海商会",
		"alignment": 2, # 中立
		"cultivation": 1, # 炼气
		"personality_tags": ["和气生财", "极其圆滑", "胆小"],
		"status": "经营坊市",
		"wealth": 99999
	})

func _register_npc(sm: Node, id: String, data_dict: Dictionary) -> void:
	var n_data = CharacterData.new()
	n_data.npc_id = id
	n_data.npc_name = data_dict.get("name", "无名氏")
	n_data.faction_id = data_dict.get("faction_name", "")
	n_data.cultivation_comp.cultivation_realm = data_dict.get("cultivation", 1)
	n_data.cultivation_comp.cultivation_stage = randi_range(1, 3) # 给个随机小境界
	n_data.cultivation_comp._refresh_max_qi()
	n_data.cultivation_comp.current_qi = randf_range(0.1, 0.9) * n_data.cultivation_comp.max_qi_cache
	n_data.current_action = data_dict.get("status", "闭关修炼")
	n_data.money = data_dict.get("wealth", 1000)
	n_data.age = data_dict.get("age", 20)
	n_data.max_lifespan = data_dict.get("max_lifespan", 100)
	n_data.combat_power = data_dict.get("combat_power", 10)
	
	# 初始化灵根
	var elements: Array[String] = []
	if n_data.faction_id == "蜀山剑派": elements = ["metal"]
	elif n_data.faction_id == "万骨窟": elements = ["water", "fire"]
	
	n_data.generate_roots_by_hierarchy(n_data.cultivation_comp.cultivation_realm, elements, true)
	
	sm.npc_attributes[id] = n_data
	
	# 分配初始物资
	var loot_allocator = sm.get_node_or_null("LootAllocator")
	if loot_allocator:
		loot_allocator.allocate_initial_loot(n_data)
