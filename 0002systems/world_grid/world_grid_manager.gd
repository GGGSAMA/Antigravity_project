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
## 将 3D 世界坐标降维转换为 2D 网格坐标
func world_to_grid(world_pos: Vector3) -> Vector2i:
	var gx = floori(world_pos.x / CHUNK_SIZE)
	var gz = floori(world_pos.z / CHUNK_SIZE)
	return Vector2i(gx, gz)

## 将 2D 网格坐标还原为其 3D 世界中心点坐标
func grid_to_world_center(grid_pos: Vector2i) -> Vector3:
	var wx = (grid_pos.x * CHUNK_SIZE) + (CHUNK_SIZE / 2.0)
	var wz = (grid_pos.y * CHUNK_SIZE) + (CHUNK_SIZE / 2.0)
	return Vector3(wx, 0.0, wz) # 高度默认 0，需要结合地形层(Terrain)重新贴地

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

var terrain: Node = null

func _ready():
	# 延迟一帧，等待整个场景树加载完毕后去寻找 Terrain3D
	call_deferred("_find_terrain")

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
	
	# 如果找到了 Terrain3D 插件，就去向它请教这块地的真实高度！
	var height = 0.0
	if terrain and "data" in terrain and terrain.data != null:
		height = terrain.data.get_height(center_pos)
	
	# ==== 地貌与灵气映射算法 ====
	if height > 50.0:
		# 极高处：雪山灵脉
		tile.biome_type = "snow_mountain"
		tile.qi_density = randf_range(3.0, 5.0)
		tile.leyline_element = 1 # 金属性
	elif height > 20.0:
		# 高处：山地丘陵
		tile.biome_type = "hills"
		tile.qi_density = randf_range(1.5, 3.0)
		tile.leyline_element = 5 # 土属性
	elif height > 2.0:
		# 平地：草地平原
		tile.biome_type = "plains"
		tile.qi_density = randf_range(0.8, 1.5)
		tile.leyline_element = 2 # 木属性
	else:
		# 极低处：水域/盆地/沼泽
		tile.biome_type = "water_swamp"
		tile.qi_density = randf_range(0.2, 0.8)
		tile.leyline_element = 3 # 水属性
	
	# 极小概率生成天道赐福地块 (可遇不可求)
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
