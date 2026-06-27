extends SceneTree

# 地貌分布比例阈值 (Biome limits: 25% each)
const OCEAN = -0.5
const PLAINS = 0.0
const HILLS = 0.5

func _init() -> void:
	print("[CLI] Loading main scene...")
	var packed = load("res://main.tscn")
	if not packed:
		print("Failed to load main.tscn")
		quit()
		return
	var scene = packed.instantiate()

	var terrain = _find_terrain(scene)
	if not terrain or not ("data" in terrain):
		print("[World Generator] Could not find Terrain3D node with valid data.")
		quit()
		return

	print("[World Generator] Starting procedural generation of Xianxia world...")
	var region_size = 1024
	var scale = 300.0 # 最大高度映射比例 (300米)

	var biome_noise = FastNoiseLite.new()
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biome_noise.frequency = 0.001

	var mountain_noise = FastNoiseLite.new()
	mountain_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	mountain_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	mountain_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE_2_ADD
	mountain_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	mountain_noise.frequency = 0.004

	var hill_noise = FastNoiseLite.new()
	hill_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	hill_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	hill_noise.frequency = 0.002

	var plains_noise = FastNoiseLite.new()
	plains_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	plains_noise.frequency = 0.01

	for rx in range(-1, 2):
		for ry in range(-1, 2):
			var img = Image.create(region_size, region_size, false, Image.FORMAT_RF)
			var offset_x = rx * region_size
			var offset_y = ry * region_size

			for x in range(region_size):
				for y in range(region_size):
					var world_x = offset_x + x
					var world_y = offset_y + y

					var b = biome_noise.get_noise_2d(world_x, world_y)
					var h = 0.0

					if b < OCEAN:
						var local_b = (b - (-1.0)) / (OCEAN - (-1.0))
						h = lerp(-40.0, -10.0, local_b)
					elif b < PLAINS:
						var local_b = (b - OCEAN) / (PLAINS - OCEAN)
						h = lerp(-10.0, 5.0, local_b) + plains_noise.get_noise_2d(world_x, world_y) * 2.0
					elif b < HILLS:
						var local_b = (b - PLAINS) / (HILLS - PLAINS)
						var base_h = lerp(5.0, 20.0, local_b)
						h = base_h + hill_noise.get_noise_2d(world_x, world_y) * 30.0 * local_b
					else:
						var local_b = (b - HILLS) / (1.0 - HILLS)
						var base_h = lerp(20.0, 60.0, local_b)
						var mount = mountain_noise.get_noise_2d(world_x, world_y)
						var steepness = pow(abs(mount), 1.5) * sign(mount)
						h = base_h + (steepness * 180.0 * local_b)

					img.set_pixel(x, y, Color(h / scale, 0, 0, 1))

			var region_loc = Vector2i(rx, ry)
			if terrain.data.has_method("add_region"):
				terrain.data.add_region(region_loc)
			elif terrain.data.has_method("add_region_blank"):
				terrain.data.add_region_blank(region_loc)

			terrain.data.import_images([img, null, null], Vector3(offset_x, 0, offset_y), 0.0, scale)
			print("[World Generator] Baked region ", rx, ", ", ry)

	if "data_directory" in terrain and terrain.data_directory != "":
		terrain.data.save_directory(terrain.data_directory)
		print("[World Generator] Saved to: ", terrain.data_directory)

	print("[World Generator] Done.")
	quit()

func _find_terrain(node: Node) -> Node:
	if node.name == "Terrain3D" or node is Terrain3D:
		return node
	for child in node.get_children():
		var res = _find_terrain(child)
		if res:
			return res
	return null
