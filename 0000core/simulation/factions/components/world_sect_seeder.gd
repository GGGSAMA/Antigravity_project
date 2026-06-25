extends Node
class_name WorldSectSeeder

func _log_trace(msg: String) -> void:
	var f = FileAccess.open("res://logs/game_full.log", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line("[%s] [WorldSectSeeder] %s" % [Time.get_time_string_from_system(), msg])
		f.close()

func seed_initial_sects(count: int = -1) -> void:
	_log_trace("=== STARTING SEED INITIAL SECTS ===")
	var fm = get_parent()
	var generator = fm.get_node_or_null("SectGenerator")
	if not generator:
		push_error("[WorldSectSeeder] SectGenerator 节点未找到！")
		_log_trace("ERROR: SectGenerator node not found!")
		return

	var world_state = get_node_or_null("/root/WorldState")
	var final_count = count
	var is_test_mode = true

	if world_state:
		if count == -1:
			final_count = world_state.sect_density
		is_test_mode = world_state.get("test_mode") if world_state.get("test_mode") != null else true
	elif final_count == -1:
		final_count = 5

	print("[WorldSectSeeder] 🌍 创世金光闪现！准备降下 ", final_count, " 个初始宗门... 测试模式: ", is_test_mode)
	_log_trace("Target sects: " + str(final_count) + " TestMode: " + str(is_test_mode))

	var terrain: Node3D = null
	if not is_test_mode and Engine.get_main_loop().root:
		terrain = Engine.get_main_loop().root.find_child("Terrain3D", true, false)

	var seeded_count = 0
	var attempts = 0
	var spawned_positions = []
	var min_distance = 300.0 # 势力之间的最小分散距离

	while seeded_count < final_count and attempts < 100:
		attempts += 1
		var random_x = randf_range(-1500.0, 1500.0)
		var random_z = randf_range(-1500.0, 1500.0)
		var spawn_pos = Vector3(random_x, 50.0, random_z)

		# 分散逻辑：检查是否离已有宗门太近
		var too_close = false
		for pos in spawned_positions:
			if Vector2(pos.x, pos.z).distance_to(Vector2(random_x, random_z)) < min_distance:
				too_close = true
				break
		if too_close:
			continue

		# 风水勘探：通过 WorldGridManager 获取地形和生态
		var tile = WorldGridManager.get_tile_at(WorldGridManager.world_to_grid(Vector3(random_x, 0, random_z)))
		
		# 屏蔽劣质风水宝地
		if tile.biome_type in ["water", "water_swamp", "desert"]:
			_log_trace("Skip: Bad FengShui Biome: " + tile.biome_type)
			continue

		var h_center = WorldGridManager.get_terrain_height(Vector3(random_x, 0, random_z))
		
		if h_center < -100.0:
			_log_trace("Skip: h_center < -100.0")
			continue

		# 半径 50 米平坦度检查（东西南北4个点）
		var r = 50.0
		var h_n = WorldGridManager.get_terrain_height(Vector3(random_x, 0, random_z - r))
		var h_s = WorldGridManager.get_terrain_height(Vector3(random_x, 0, random_z + r))
		var h_e = WorldGridManager.get_terrain_height(Vector3(random_x + r, 0, random_z))
		var h_w = WorldGridManager.get_terrain_height(Vector3(random_x - r, 0, random_z))

		var h_max = max(h_center, max(h_n, max(h_s, max(h_e, h_w))))
		var h_min = min(h_center, min(h_n, min(h_s, min(h_e, h_w))))

		# 最大落差检查（如果落差太大，说明在陡峭的山坡上，不可建宗！）
		if h_max - h_min > 12.0:
			_log_trace("Skip: height difference too large: " + str(h_max - h_min))
			continue

		var h = h_center

		spawn_pos.y = h

		# 呼叫建造局
		_log_trace("Spawning sect at: " + str(spawn_pos))
		generator.create_sect_at_location(spawn_pos, "")
		spawned_positions.append(spawn_pos)
		seeded_count += 1

	# 如果100次尝试都没找够，强行生成剩下的
	if seeded_count < final_count:
		_log_trace("Fallback generation triggered. Needed " + str(final_count - seeded_count) + " more.")
		print("[WorldSectSeeder] ⚠️ 分散度要求过高或风水极端，部分宗门强行降世...")
		for i in range(final_count - seeded_count):
			var random_x = randf_range(-1500.0, 1500.0)
			var random_z = randf_range(-1500.0, 1500.0)
			var spawn_pos = Vector3(random_x, 0.0, random_z)
			if terrain and "data" in terrain and terrain.data:
				var h = terrain.data.get_height(Vector3(random_x, 0, random_z))
				if not is_nan(h):
					spawn_pos.y = h
				else:
					_log_trace("Fallback position also returned NaN height! Using y=0.0")

			_log_trace("Spawning fallback sect at: " + str(spawn_pos))
			generator.create_sect_at_location(spawn_pos, "")
			seeded_count += 1

	print("[WorldSectSeeder] 🌍 播种完毕！成功降世了 ", seeded_count, " 个初始宗门！修仙界开始运转！")
	_log_trace("=== FINISHED SEEDING ===")
