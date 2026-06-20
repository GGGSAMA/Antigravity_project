@tool
extends EditorScript

# ==============================================================================
# WORLD GENERATOR (XIANXIA BIOME ENGINE)
# ==============================================================================
# Overall Function:
# This script is responsible for procedurally generating the heightmap data for 
# a 3x3 region grid (3072x3072 meters) in the Godot Terrain3D plugin.
# It simulates four distinct biomes: Ocean, Plains, Hills, and Steep Mountains (Xianxia style).
#
# Structural Logic:
# 1. Utilizes FastNoiseLite to create a macro biome map (Simplex).
# 2. Uses distinct noise layers (Cellular for Mountains, Simplex for Hills/Plains) 
#    to define the height characteristics of each biome.
# 3. Iterates over 9 regions (each 1024x1024), calculates the height per vertex, 
#    and bakes the data directly into Image.FORMAT_RF.
# 4. Imports the generated image arrays into Terrain3DData via `import_images`.
# 5. Automatically generates invisible physical air walls (StaticBody3D) surrounding the playable area.
#
# Usage Requirements / Specific Settings:
# - IMPORTANT: Terrain3D requires memory regions to be allocated BEFORE importing.
#   You MUST manually use the 'Add Region' tool in the Terrain3D editor toolbar to 
#   add a 3x3 grid of regions centered around your spawn point before running this script.
# - Execute this script via the Godot Script Editor: `File -> Run` (Ctrl+Shift+X).
# - WARNING: Generation processes over 9 million vertices on the main thread and 
#   WILL FREEZE THE EDITOR for 10-30 seconds. This is expected behavior.
# ==============================================================================

# 地貌分布比例阈值 (Biome limits: ~25% distribution each)
const OCEAN = -0.5
const PLAINS = 0.0
const HILLS = 0.5


# 主执行入口：从编辑器菜单运行此脚本时触发
func _run() -> void:
	# 设置本地日志输出，用于 AI 和开发者调试（因为编辑器控制台缓冲区可能被冲刷）
	var log_file = FileAccess.open("res://generator_log.txt", FileAccess.WRITE)
	if log_file:
		log_file.store_line("[World Generator] Started.")
	var print_log = func(msg):
		print(msg)
		if log_file:
			log_file.store_line(str(msg))

	var scene = get_scene()
	if not scene:
		print_log.call("[World Generator] ERROR: No active scene found. Run this in the editor with main.tscn open.")
		return
		
	var terrain = _find_terrain(scene)
	if not terrain or not ("data" in terrain):
		print_log.call("[World Generator] Could not find Terrain3D node with valid data.")
		return
		
	print_log.call("[World Generator] Starting procedural generation of Xianxia world...")
	var region_size = 1024
	var scale = 300.0 # 最大高度映射比例 (300米)
	
	# === 1. 宏观地貌划分噪声 (Biome Map) ===
	var biome_noise = FastNoiseLite.new()
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biome_noise.frequency = 0.001 # 频率设为 0.001，确保在 3000 米范围内能看到所有地貌
	biome_noise.seed = randi()
	
	# === 2. 陡峭仙山噪声 (Steep Mountains) ===
	var mountain_noise = FastNoiseLite.new()
	mountain_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	mountain_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	mountain_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_ADD
	mountain_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	mountain_noise.frequency = 0.004
	mountain_noise.seed = randi()
	
	# === 3. 丘陵噪声 (Hills) ===
	var hill_noise = FastNoiseLite.new()
	hill_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	hill_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	hill_noise.frequency = 0.002
	hill_noise.seed = randi()
	
	# === 4. 平原噪声 (Plains) ===
	var plains_noise = FastNoiseLite.new()
	plains_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	plains_noise.frequency = 0.01
	plains_noise.seed = randi()
	
	# 生成 3x3 区域 (涵盖 -1536 到 1536，总计 9 平方公里)
	for rx in range(-1, 2):
		for ry in range(-1, 2):
			var img = Image.create_empty(region_size, region_size, false, Image.FORMAT_RF)
			var offset_x = rx * region_size
			var offset_y = ry * region_size
			
			for x in range(region_size):
				for y in range(region_size):
					var world_x = offset_x + x
					var world_y = offset_y + y
					
					# b 的范围在 -1.0 到 1.0 之间
					var b = biome_noise.get_noise_2d(world_x, world_y)
					var h = 0.0
					
					if b < OCEAN:
						# 海洋 (-1.0 to -0.5)
						# 平滑过渡到 -20 米
						var local_b = (b - (-1.0)) / (OCEAN - (-1.0)) # 0 到 1
						h = lerp(-40.0, -10.0, local_b)
						
					elif b < PLAINS:
						# 平原 (-0.5 to 0.0)
						var local_b = (b - OCEAN) / (PLAINS - OCEAN) # 0 到 1
						h = lerp(-10.0, 5.0, local_b) + plains_noise.get_noise_2d(world_x, world_y) * 2.0
						
					elif b < HILLS:
						# 丘陵 (0.0 to 0.5)
						var local_b = (b - PLAINS) / (HILLS - PLAINS)
						# 保证丘陵边缘接壤平原
						var base_h = lerp(5.0, 20.0, local_b)
						h = base_h + hill_noise.get_noise_2d(world_x, world_y) * 30.0 * local_b
						
					else:
						# 陡峭仙山 (0.5 to 1.0)
						var local_b = (b - HILLS) / (1.0 - HILLS)
						# 仙山基底高度
						var base_h = lerp(20.0, 60.0, local_b)
						var mount = mountain_noise.get_noise_2d(world_x, world_y)
						# mount 通常在 -1 到 1，但在 RIDGED 模式下会有高耸的峰值
						# 使用 pow 增加陡峭感
						var steepness = pow(abs(mount), 1.5) * sign(mount)
						h = base_h + (steepness * 180.0 * local_b)
					
					# 在 Godot 4 的 Terrain3D 中，FORMAT_RF 直接存储真实的物理高度值，不需要做任何归一化！
					# 之前的 (h / scale) 把最高 60 米的山峰除以 300 变成了 0.2 米的平地，这是罪魁祸首！
					img.set_pixel(x, y, Color(h, 0, 0, 1))
					
			# 导入数据到当前 Terrain3D 节点
			# 使用 scale = 1.0，因为已经是真实高度
			terrain.data.import_images([img, null, null], Vector3(offset_x, 0, offset_y), 0.0, 1.0)
			print_log.call(str("[World Generator] Baked region ", rx, ", ", ry))
			
	var save_dir = "res://demo/data"
	if "data_directory" in terrain and terrain.data_directory != "":
		save_dir = terrain.data_directory
		
	terrain.data.save_directory(save_dir)
	print_log.call(str("[World Generator] Saved to: ", save_dir))
		
	_build_air_walls(scene)
	print_log.call("[World Generator] World Generation Complete! Regions saved to Terrain3D Data.")
	
	if log_file:
		log_file.close()

# 递归查找场景树中的 Terrain3D 节点
# 用于在未明确指定路径时动态定位地形节点
func _find_terrain(node: Node) -> Node:
	if node.name == "Terrain3D" or node is Terrain3D:
		return node
	for child in node.get_children():
		var res = _find_terrain(child)
		if res:
			return res
	return null

# 根据生成的 3x3 区域，在地图边缘动态构建隐形空气墙（WorldBoundaries）
# 确保玩家和 NPC 不会掉出世界边缘导致物理引擎崩溃
func _build_air_walls(scene: Node) -> void:
	# 先检查是否已经有了空气墙节点，如果有就删掉重建
	var old_walls = scene.get_node_or_null("WorldBoundaries")
	if old_walls:
		old_walls.name = "DeletedBoundaries"
		old_walls.queue_free()
		
	var boundaries = StaticBody3D.new()
	boundaries.name = "WorldBoundaries"
	scene.add_child(boundaries)
	boundaries.owner = scene # 必须设置 owner 才能存进 .tscn
	
	# 根据 3x3 区域 (-1 到 +1) 计算边界
	# X 和 Z 的范围都是 -1024 到 2048，中心点在 (512, 512)，跨度 3072
	var min_bound = -1024.0
	var max_bound = 2048.0
	var center = (min_bound + max_bound) / 2.0
	var length = max_bound - min_bound
	var thickness = 100.0
	var wall_height = 800.0
	var y_center = 200.0 # 从 -200 到 600 高度
	
	# 北墙 (Z = min)
	var n_shape = CollisionShape3D.new()
	n_shape.name = "NorthWall"
	var n_box = BoxShape3D.new()
	n_box.size = Vector3(length + thickness*2, wall_height, thickness)
	n_shape.shape = n_box
	n_shape.position = Vector3(center, y_center, min_bound - thickness/2)
	boundaries.add_child(n_shape)
	n_shape.owner = scene
	
	# 南墙 (Z = max)
	var s_shape = CollisionShape3D.new()
	s_shape.name = "SouthWall"
	var s_box = BoxShape3D.new()
	s_box.size = Vector3(length + thickness*2, wall_height, thickness)
	s_shape.shape = s_box
	s_shape.position = Vector3(center, y_center, max_bound + thickness/2)
	boundaries.add_child(s_shape)
	s_shape.owner = scene
	
	# 西墙 (X = min)
	var w_shape = CollisionShape3D.new()
	w_shape.name = "WestWall"
	var w_box = BoxShape3D.new()
	w_box.size = Vector3(thickness, wall_height, length)
	w_shape.shape = w_box
	w_shape.position = Vector3(min_bound - thickness/2, y_center, center)
	boundaries.add_child(w_shape)
	w_shape.owner = scene
	
	# 东墙 (X = max)
	var e_shape = CollisionShape3D.new()
	e_shape.name = "EastWall"
	var e_box = BoxShape3D.new()
	e_box.size = Vector3(thickness, wall_height, length)
	e_shape.shape = e_box
	e_shape.position = Vector3(max_bound + thickness/2, y_center, center)
	boundaries.add_child(e_shape)
	e_shape.owner = scene
	
	print("[World Generator] Invisible Air Walls created around [-1024, 2048].")
