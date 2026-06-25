extends Node

## -----------------------------------------------------------------------------
## WorldGridManager - 开放世界大网格底层数据单例
## -----------------------------------------------------------------------------

## 每个逻辑网格代表 3D 世界中多大的正方形区域？ (单位：米)
const CHUNK_SIZE: float = 100.0

## 核心数据账本：存储所有已被探索/生成的网格
## Key: Vector2i, Value: WorldTile
var grid: Dictionary = {}

## 当一个地块的属性发生重大变化时发射，通知 Shader 或 UI 更新
signal tile_updated(grid_pos: Vector2i, tile: WorldTile)
signal sect_territory_changed(sect_id: String, grid_pos: Vector2i, is_claimed: bool)

## ------------------ 坐标换算核心算法 ------------------

## 安全获取地形高度接口 (Terrain Seam)
func get_terrain_height(world_pos: Vector3) -> float:
	if terrain and "data" in terrain and terrain.data != null:
		var h = terrain.data.get_height(world_pos)
		if not is_nan(h):
			return h
	return 0.0

## 将 3D 世界坐标降维转换为 2D 网格坐标
func world_to_grid(world_pos: Vector3) -> Vector2i:
	var gx = floori(world_pos.x / CHUNK_SIZE)
	var gz = floori(world_pos.z / CHUNK_SIZE)
	return Vector2i(gx, gz)

## 将 2D 网格坐标还原为其 3D 世界中心点坐标
func grid_to_world_center(grid_pos: Vector2i) -> Vector3:
	var wx = (grid_pos.x * CHUNK_SIZE) + (CHUNK_SIZE / 2.0)
	var wz = (grid_pos.y * CHUNK_SIZE) + (CHUNK_SIZE / 2.0)
	# 通过 Terrain Seam 动态抓取真实高度，彻底消灭高度孤岛
	var wy = get_terrain_height(Vector3(wx, 0.0, wz))
	return Vector3(wx, wy, wz)

## ------------------ 数据读取接口 ------------------
## 获取指定坐标的地块，如果不存在则自动生成一个默认地块（稀疏矩阵机制）
func get_tile_at(grid_pos: Vector2i) -> WorldTile:
	if not grid.has(grid_pos):
		_generate_default_tile(grid_pos)
	return grid[grid_pos]

## 获取真实 3D 坐标下的地块属性
func get_tile_at_world_pos(world_pos: Vector3) -> WorldTile:
	return get_tile_at(world_to_grid(world_pos))

## ------------------ 业务逻辑接口 ------------------
## 修改地块宗门归属
func claim_tile(world_pos: Vector3, new_sect_id: String, influence: float = 1.0) -> void:
	var grid_pos = world_to_grid(world_pos)
	var tile = get_tile_at(grid_pos)

	if tile.owner_sect_id != new_sect_id:
		var old_sect = tile.owner_sect_id
		tile.owner_sect_id = new_sect_id
		tile.control_influence = influence

		# 触发领地变更事件
		if old_sect != "":
			sect_territory_changed.emit(old_sect, grid_pos, false)
		sect_territory_changed.emit(new_sect_id, grid_pos, true)
		tile_updated.emit(grid_pos, tile)

## 批量修改多个地块宗门归属 (基于网格半径)
func claim_territory_radius(world_pos: Vector3, radius_tiles: int, sect_id: String) -> void:
	var center_grid = world_to_grid(world_pos)
	for x in range(-radius_tiles, radius_tiles + 1):
		for y in range(-radius_tiles, radius_tiles + 1):
			var target_grid = center_grid + Vector2i(x, y)
			var target_world_pos = grid_to_world_center(target_grid)
			claim_tile(target_world_pos, sect_id, 1.0)


## 增加地块邪气值（腐化度）
func add_corruption(world_pos: Vector3, amount: float) -> void:
	var grid_pos = world_to_grid(world_pos)
	var tile = get_tile_at(grid_pos)

	tile.corruption_level = clamp(tile.corruption_level + amount, 0.0, 1.0)
	tile_updated.emit(grid_pos, tile)

## 核心消耗瓶颈：从天地中强行抽取资源 (竭泽而渔防逃课接口)
## 返回实际抽取到的数量。如果地块已经被薅秃了，返回 0，任你什么灵丹妙药也刷不出资源！
func extract_resource(world_pos: Vector3, item_id: String, requested_amount: int) -> int:
	var grid_pos = world_to_grid(world_pos)
	var tile = get_tile_at(grid_pos)
	
	if not tile.ecology_inventory.has(item_id):
		return 0
		
	var current_stock = tile.ecology_inventory[item_id]
	if current_stock <= 0:
		return 0
		
	var extracted = min(current_stock, requested_amount)
	tile.ecology_inventory[item_id] = current_stock - extracted
	
	# 如果一瞬间把库存抽干了，记录日志（后续 ChunkEcologyManager 会概率触发灵脉受损）
	if tile.ecology_inventory[item_id] <= 0:
		print("[天道警告] 地块 %s 的 %s 已被彻底竭泽而渔！" % [str(grid_pos), item_id])
		
	tile_updated.emit(grid_pos, tile)
	return extracted

var terrain: Node = null

# 生态系统噪声生成器
var temp_noise: FastNoiseLite = FastNoiseLite.new()
var humid_noise: FastNoiseLite = FastNoiseLite.new()

func _ready():
	# 延迟一帧，等待整个场景树加载完毕后去寻找 Terrain3D
	call_deferred("_find_terrain")
	
	# 初始化生态噪声
	temp_noise.seed = randi()
	temp_noise.frequency = 0.005 # 大面积温度渐变
	humid_noise.seed = randi() + 100
	humid_noise.frequency = 0.005
	
	# 挂载天道生态管理器 (ChunkEcologyManager)
	var ecology_manager = ChunkEcologyManager.new()
	ecology_manager.name = "ChunkEcologyManager"
	add_child(ecology_manager)

func _find_terrain():
	terrain = _find_terrain_node(get_tree().root)

func _find_terrain_node(node: Node) -> Node:
	if node.get_class() == "Terrain3D":
		return node
	for child in node.get_children():
		var res = _find_terrain_node(child)
		if res: return res
	return null

## ------------------ 内部方法 ------------------
## 按需生成地块，动态结合 Terrain3D 高度数据生成灵气和生态
func _generate_default_tile(grid_pos: Vector2i) -> void:
	var tile = WorldTile.new()
	var center_pos = grid_to_world_center(grid_pos)
	var height = center_pos.y # grid_to_world_center 已经集成了真实的物理高度
	
	# 获取该网格的温度与湿度 (-1.0 到 1.0)
	var temp = temp_noise.get_noise_2d(center_pos.x, center_pos.z)
	var humid = humid_noise.get_noise_2d(center_pos.x, center_pos.z)

	# ==== 全息生态与灵气演化算法 ====
	if height > 40.0:
		if temp < 0.0:
			tile.biome_type = "snow_mountain"
			tile.qi_density = randf_range(3.0, 5.0)
			tile.leyline_element = 1 # 金
		else:
			tile.biome_type = "spiritual_hills" # 仙山灵脉
			tile.qi_density = randf_range(4.0, 6.0)
			tile.leyline_element = 2 # 木
	elif height < 5.0:
		if temp > 0.2 and humid > 0.2:
			tile.biome_type = "jungle_swamp" # 毒沼密林
			tile.qi_density = randf_range(0.5, 1.5)
			tile.corruption_level = randf_range(0.2, 0.6) # 自带毒瘴
			tile.leyline_element = 3 # 水
		else:
			tile.biome_type = "water" # 普通水域
			tile.qi_density = randf_range(0.2, 0.8)
			tile.leyline_element = 3 # 水
	else:
		if temp > 0.4 and humid < -0.2:
			tile.biome_type = "desert" # 灼热荒漠
			tile.qi_density = randf_range(0.5, 1.0)
			tile.leyline_element = 4 # 火
		elif temp > -0.2 and temp <= 0.4:
			tile.biome_type = "plains" # 凡尘平原
			tile.qi_density = randf_range(1.0, 2.0)
			tile.leyline_element = 5 # 土
		else:
			tile.biome_type = "hills" # 普通丘陵
			tile.qi_density = randf_range(1.5, 2.5)
			tile.leyline_element = 5 # 土

	# 极小概率生成天道赐福地块
	if randf() < 0.01:
		tile.fortune_level = 1.0
		tile.qi_density *= 3.0 # 灵气暴涨

	grid[grid_pos] = tile

## ------------------ 存取档接口 ------------------
## 序列化所有非默认地块
func save_map_data() -> Dictionary:
	var saved_data = {}
	for key in grid.keys():
		var str_key = str(key.x) + "," + str(key.y)
		saved_data[str_key] = grid[key].to_dict()
	return saved_data

## 反序列化恢复地图
func load_map_data(data: Dictionary) -> void:
	grid.clear()
	for str_key in data.keys():
		var parts = str_key.split(",")
		var gx = int(parts[0])
		var gy = int(parts[1])
		var tile = WorldTile.new()
		tile.from_dict(data[str_key])
		grid[Vector2i(gx, gy)] = tile
