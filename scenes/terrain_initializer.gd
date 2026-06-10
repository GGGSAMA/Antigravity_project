@tool
extends Terrain3D

func _ready() -> void:
	# Ensure data directory is configured
	if data_directory == "":
		data_directory = "res://terrain_data"
	
	# Wait a frame for GDExtension to fully initialize
	await get_tree().process_frame
	
	if data:
		var regions = data.get_regions_active()
		var needs_regen = regions.size() == 0
		if assets:
			if assets.get_texture_count() < 3:
				needs_regen = true
		else:
			needs_regen = true
			
		if needs_regen:
			print("[TerrainInitializer] Generating procedural terrain and low-res PBR textures...")
			generate_procedural_world()
		else:
			print("[TerrainInitializer] Active regions already exist and are initialized: ", regions)

func generate_procedural_world() -> void:
	# 1. Create and configure low-res PBR texture assets (Grass, Rock, Clay)
	# Using 16x16 pixelated colors with random noise for a Minecraft-like style
	var grass_ta := create_texture_asset("Grass", "grass")
	grass_ta.uv_scale = 0.15
	grass_ta.detiling_rotation = 0.0
	
	var stone_ta := create_texture_asset("Rock", "stone")
	stone_ta.uv_scale = 0.15
	stone_ta.detiling_rotation = 0.0
	
	var clay_ta := create_texture_asset("Clay", "clay")
	clay_ta.uv_scale = 0.15
	clay_ta.detiling_rotation = 0.0
	
	# Instantiate assets resource
	assets = Terrain3DAssets.new()
	assets.set_texture(0, grass_ta)
	assets.set_texture(1, stone_ta)
	assets.set_texture(2, clay_ta)
	
	# 2. Configure material for auto-shader (flat=grass, steep=rock)
	material.auto_shader = true
	if material.has_method("set_shader_param"):
		material.set_shader_param("auto_slope", 1.0)
		material.set_shader_param("blend_sharpness", 0.85)
	
	# 3. Generate heightmap & control map w/ FastNoiseLite
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.003
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	
	var size = 2048
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RF)
	var ctrl_img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0  # 1024
	
	for x in size:
		for y in size:
			var world_x = x - center
			var world_z = y - center
			var dist = sqrt(world_x * world_x + world_z * world_z)
			
			# Flatten a radius around the spawn point (0, 0)
			var mask = 0.0
			if dist < 60.0:
				mask = 0.0
			elif dist < 250.0:
				mask = (dist - 60.0) / (250.0 - 60.0)
				# smoothstep-like curve for nicer transition
				mask = mask * mask * (3.0 - 2.0 * mask)
			else:
				mask = 1.0
				
			var noise_val = (noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5
			var height = noise_val * mask
			
			img.set_pixel(x, y, Color(height, 0.0, 0.0, 1.0))
			
			# Paint textures:
			# For dist < 60.0 (temple flat area), paint Clay/Dirt (index 2)
			# Otherwise, paint Grass (index 0). Slope-based Rock (index 1) will be overlaid by the auto-shader.
			if dist < 60.0:
				# Red=2 (Base index), Green=2 (Overlay index), Blue=0 (Blend weight = 0), Alpha=1 (No flags)
				ctrl_img.set_pixel(x, y, Color(2.0/255.0, 2.0/255.0, 0.0, 1.0))
			else:
				# Red=0, Green=0, Blue=0, Alpha=1
				ctrl_img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 1.0))
				
	# Import the generated heightmap and control map
	data.import_images([img, ctrl_img, null], Vector3(-center, 0, -center), 0.0, 60.0)
	print("[TerrainInitializer] Procedural world generation completed with low-res PBR textures.")

func create_texture_asset(asset_name: String, type: String) -> Terrain3DTextureAsset:
	var alb_img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var nrm_img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	
	# Seed random number generator to ensure consistent procedurally generated textures
	var seed_val = asset_name.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	for x in 16:
		for y in 16:
			var r: float = 0.0
			var g: float = 0.0
			var b: float = 0.0
			var a: float = 0.5
			var nx: float = 0.5
			var ny: float = 0.5
			var roughness: float = 0.8
			
			if type == "grass":
				var brightness = rng.randf_range(0.85, 1.15)
				var hue_shift = rng.randf_range(-0.03, 0.03)
				r = clamp(0.24 * brightness + hue_shift, 0.0, 1.0)
				g = clamp(0.46 * brightness + hue_shift, 0.0, 1.0)
				b = clamp(0.18 * brightness, 0.0, 1.0)
				a = clamp(0.5 + rng.randf_range(-0.15, 0.15), 0.0, 1.0)
				roughness = clamp(0.9 + rng.randf_range(-0.05, 0.05), 0.0, 1.0)
			elif type == "clay":
				var brightness = rng.randf_range(0.9, 1.1)
				r = clamp(0.52 * brightness, 0.0, 1.0)
				g = clamp(0.40 * brightness, 0.0, 1.0)
				b = clamp(0.25 * brightness, 0.0, 1.0)
				a = clamp(0.5 + rng.randf_range(-0.1, 0.1), 0.0, 1.0)
				roughness = clamp(0.95 + rng.randf_range(-0.03, 0.03), 0.0, 1.0)
			elif type == "stone":
				var brightness = rng.randf_range(0.75, 1.25)
				r = clamp(0.32 * brightness, 0.0, 1.0)
				g = clamp(0.32 * brightness, 0.0, 1.0)
				b = clamp(0.32 * brightness, 0.0, 1.0)
				a = clamp(0.5 + rng.randf_range(-0.25, 0.25), 0.0, 1.0)
				# Bumpy normal
				nx = clamp(0.5 + rng.randf_range(-0.12, 0.12), 0.0, 1.0)
				ny = clamp(0.5 + rng.randf_range(-0.12, 0.12), 0.0, 1.0)
				roughness = clamp(0.65 + rng.randf_range(-0.08, 0.08), 0.0, 1.0)
			
			alb_img.set_pixel(x, y, Color(r, g, b, a))
			nrm_img.set_pixel(x, y, Color(nx, ny, 1.0, roughness))
			
	var albedo := ImageTexture.create_from_image(alb_img)
	var normal := ImageTexture.create_from_image(nrm_img)
	
	var ta := Terrain3DTextureAsset.new()
	ta.name = asset_name
	ta.albedo_texture = albedo
	ta.normal_texture = normal
	return ta
