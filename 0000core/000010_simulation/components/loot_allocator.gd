extends Node
class_name LootAllocator

const CharacterData = preload("res://0000core/000010_simulation/entities/character_data.gd")

func allocate_initial_loot(data: CharacterData) -> void:
	var realm = data.cultivation_comp.cultivation_realm if data and data.cultivation_comp else 1

	# 随机生成初始身家与物品 (根据境界与世界灵气丰度)
	var world_state = get_node_or_null("/root/WorldState")
	var richness: float = 1.0
	if world_state:
		richness = world_state.resource_richness

	data.money += int(randi_range(500, 2000) * realm * richness)
	var pool = ["小还丹", "聚灵散", "五毒散", "千里传送令"]

	# 给每个NPC随机塞1~4种不同物品，数量也是随机的
	for i in range(randi_range(1, 4)):
		var item_id = pool[randi() % pool.size()]
		var qty = int(randi_range(1, 3 * realm) * richness)
		if qty > 0:
			data.inventory[item_id] = data.inventory.get(item_id, 0) + qty

	# 如果是高阶修士，可能塞极品丹药
	if realm >= 3:
		var top_qty = int(randi_range(1, 2) * richness)
		if top_qty > 0:
			data.inventory["九转金丹"] = top_qty
