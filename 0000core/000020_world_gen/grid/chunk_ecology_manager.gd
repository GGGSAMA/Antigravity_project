class_name ChunkEcologyManager
extends Node

## -----------------------------------------------------------------------------
## ChunkEcologyManager - 天道产出锁死与刷新机制
## 此管理器负责进行大世界的低频、大规模资源生长，强物理锁死产出上限。
## -----------------------------------------------------------------------------

## 宏观生长周期（天），即每隔多少天“天道”下场结算一次草药矿石刷新
const MACRO_GROWTH_CYCLE_DAYS: int = 10

## 不同生态默认会产出的基础资源 ID 列表，以及基础产量权重
const BIOME_DROP_TABLES = {
	"forest": {"herb_low": 2.0, "wood_spirit": 1.0},
	"desert": {"ore_iron": 1.5, "herb_fire": 0.5},
	"snow_mountain": {"ore_ice": 1.0, "herb_snow": 0.2},
	"spiritual_hills": {"herb_mid": 1.0, "ore_spirit": 1.0},
	"jungle_swamp": {"herb_poison": 2.0, "wood_rot": 1.0},
	"plains": {"herb_low": 1.0, "ore_iron": 0.5},
	"hills": {"ore_iron": 2.0, "herb_low": 0.5},
	"water": {"fish_spirit": 1.5, "herb_water": 0.5}
}

func _ready() -> void:
	# 等待一帧以确保 TimeManager 已经准备就绪
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var tm = Engine.get_main_loop().root.get_node_or_null("TimeManager")
	if tm:
		tm.day_passed.connect(_on_day_passed)

## 每天触发，检查是否到达结算周期
func _on_day_passed() -> void:
	var tm = Engine.get_main_loop().root.get_node_or_null("TimeManager")
	if not tm: return
	
	var current_day = tm.get_current_day()
	if current_day > 0 and current_day % MACRO_GROWTH_CYCLE_DAYS == 0:
		_process_macro_growth(current_day)

## 执行宏观世界生长结算 (天道下场)
func _process_macro_growth(current_day: int) -> void:
	print("[ChunkEcologyManager] 天道运转，万物复苏。开始进行 %d 天周期的生态刷新结算..." % MACRO_GROWTH_CYCLE_DAYS)
	var wgm = Engine.get_main_loop().root.get_node_or_null("WorldGridManager")
	if not wgm: return

	# 遍历所有已生成的网格
	for grid_pos in wgm.grid.keys():
		var tile: WorldTile = wgm.grid[grid_pos]
		_simulate_tile_growth(tile, current_day)

func _simulate_tile_growth(tile: WorldTile, current_day: int) -> void:
	# 防止重复刷新（如果有错位）
	if current_day - tile.last_growth_day < MACRO_GROWTH_CYCLE_DAYS:
		return
	
	tile.last_growth_day = current_day

	# 根据生态获取掉落表
	var drop_table = BIOME_DROP_TABLES.get(tile.biome_type, {})
	if drop_table.is_empty():
		return

	# 初始化地块容量 (Capacity)
	# 容量计算公式：基础容量 * 灵气密度 * 资源富集度
	if tile.ecology_capacity.is_empty():
		var base_cap_multiplier = 50.0 # 基础容量基数
		for item_id in drop_table.keys():
			var weight = drop_table[item_id]
			# 天道赐福 (fortune_level) 会极大提升极品容量
			var cap = int(base_cap_multiplier * weight * tile.qi_density * tile.resource_richness * (1.0 + tile.fortune_level * 2.0))
			tile.ecology_capacity[item_id] = max(1, cap)

	# 执行生长注入 (Inventory Injection)
	for item_id in tile.ecology_capacity.keys():
		var max_cap = tile.ecology_capacity[item_id]
		var current_stock = tile.ecology_inventory.get(item_id, 0)
		
		# 如果已经被挖空，或者没满，开始生长
		if current_stock < max_cap:
			# 每次生长恢复最大容量的 20%~40%，灵气越高恢复越快
			var growth_ratio = randf_range(0.2, 0.4) * (tile.qi_density * 0.5 + 0.5)
			var growth_amount = int(max_cap * growth_ratio)
			growth_amount = max(1, growth_amount) # 至少长1个
			
			tile.ecology_inventory[item_id] = min(max_cap, current_stock + growth_amount)
