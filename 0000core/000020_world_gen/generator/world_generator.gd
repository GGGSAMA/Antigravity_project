extends Node3D
class_name WorldGenerator

@export var terrain_node: Terrain3D
@export var terrain_size: int = 2048 # 降回 2048 避免启动卡死，2048 已经有大约 2 公里的宏大视野
@export var height_scale: float = 2400.0 # 高度翻3倍

var noise: FastNoiseLite

func _ready() -> void:
	if not terrain_node:
		var root = get_tree().current_scene if get_tree().current_scene else get_tree().root
		terrain_node = _find_terrain3d(root)
		if not terrain_node:
			push_error("WorldGenerator: Terrain3D node not found!")
			return

	var current_seed = "默认神界"
	if has_node("/root/WorldState"):
		current_seed = get_node("/root/WorldState").current_seed

	print("WorldGenerator starting generation with seed: ", current_seed)

	# 你之前的像剑锋一样的山脉，我们备份并记录为“剑冢山脉”参数
	# _generate_sword_tomb_mountains(current_seed) 

	# 使用新的“平地+大山脉”的地形生成
	_generate_mixed_terrain(current_seed)

func _find_terrain3d(node: Node) -> Node:
	if node.get_class() == "Terrain3D" or node is Terrain3D:
		return node
	for child in node.get_children():
		var t = _find_terrain3d(child)
		if t:
			return t
	return null

# 【参数备份】剑冢山脉：极其尖锐、刀削斧劈的均匀剑锋地形
func _generate_sword_tomb_mountains(seed_str: String) -> void:
	noise = FastNoiseLite.new()
	noise.seed = seed_str.hash()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED # Ridged 生成尖锐山脊
	noise.fractal_octaves = 6
	noise.frequency = 0.003
	# 核心算法：pow(normalized, 2.5) * 800.0

# 【当前需求】平原与巨大山脉混合的地形
func _generate_mixed_terrain(seed_str: String) -> void:
	print("正在生成 万米级大地图（平原+大山脉），GDScript 循环次数较大，请耐心等待几秒...")
	noise = FastNoiseLite.new()
	noise.seed = seed_str.hash()

	# 使用 FBM 分形生成更加自然的平滑丘陵和山体，不再那么尖锐
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.frequency = 0.0005 # 频率极低，板块非常宽广

	var img_size = terrain_size # 8192x8192 约 6700 万像素点
	var height_img = Image.create_empty(img_size, img_size, false, Image.FORMAT_RF)
	var half_size = img_size / 2

	for y in range(img_size):
		for x in range(img_size):
			var world_x = x - half_size
			var world_z = y - half_size

			var n_val = noise.get_noise_2d(world_x, world_z)
			var normalized = (n_val + 1.0) * 0.5

			# 核心算法：用阈值分离平原与山脉
			# 小于 0.4 的区域高度全部为 0（绝对平原）
			var h = 0.0
			if normalized > 0.4:
				# 大于 0.4 的区域开始隆起成为山脉
				var mountain_val = (normalized - 0.4) / 0.6
				# 使用平方来让山体有起伏，但因为使用的是 FBM，所以不会像之前 Ridged 那样尖锐
				h = pow(mountain_val, 2.0) * height_scale

			# 边缘衰减，防止地图边缘发生突然断层
			var dist_x = abs(float(world_x) / float(half_size))
			var dist_z = abs(float(world_z) / float(half_size))
			var edge_dist = max(dist_x, dist_z)
			if edge_dist > 0.8:
				var falloff = 1.0 - ((edge_dist - 0.8) / 0.2)
				h *= falloff

			height_img.set_pixel(x, y, Color(h, 0, 0))

	var control_img = Image.create_empty(img_size, img_size, false, Image.FORMAT_RGB8)
	var color_img = Image.create_empty(img_size, img_size, false, Image.FORMAT_RGBA8)
	color_img.fill(Color.WHITE)

	var images: Array[Image] = [height_img, control_img, color_img]

	# 位置居中，配合 (2048, 2048) 图片的边界
	var offset_pos = Vector3(-1024.0, 0, -1024.0)

	if terrain_node.data:
		print("Importing Mixed Terrain heightmap into Terrain3D...")
		terrain_node.data.import_images(images, offset_pos, 0.0, 1.0)
		if terrain_node.material:
			terrain_node.material.show_checkered = true
		print("Mixed Terrain Generation Completed!")

		# ======================================================================
		# 创世最后一步：向世界大地上撒下初始宗门的种子
		# ======================================================================
		var faction_manager = get_node_or_null("/root/FactionManager")
		if faction_manager and faction_manager.has_method("seed_initial_world"):
			faction_manager.seed_initial_world(5) # 默认撒 5 个宗门

	else:
		push_error("Terrain3D has no data instance!")
