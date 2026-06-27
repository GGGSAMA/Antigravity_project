# ==============================================================================
# WorldSectSeeder (创世宗门播种机)
# 
# [设计意图 / Design Intent]:
# 负责在世界生成初期（或文明推演开始时），在广袤的 3D 世界中随机播撒初始宗门。
# 它封装了风水勘探算法（Terrain Height, Biome 检查，坡度平整性校验等）。
#
# [架构职责 / Responsibilities]:
# 1. 在指定的坐标系内寻找适合建立宗门的合法 3D 坐标。
# 2. 保证宗门之间的势力范围不会过度重叠（维持最小距离）。
# 3. 规避水域、无效地块及虚空坐标。
# 4. 在多次尝试失败后，执行安全的 Fallback（强制生成）机制。
# ==============================================================================
extends Node
class_name WorldSectSeeder

func _log_trace(msg: String) -> void:
	var f = FileAccess.open("res://logs/game_full.log", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line("[%s] [WorldSectSeeder] %s" % [Time.get_time_string_from_system(), msg])
		f.close()

## 开始世界范围内的初始宗门播种
## @param count: 期望生成的宗门数量。如果为 -1，则从全局配置读取密度。
## @description:
## 该函数会尝试循环 100 次以满足理想的风水条件。若条件过于苛刻导致失败，
## 会退化为 Fallback 强制生成，但依然保证生成坐标在地表之上。
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
			_log_trace("Skip: h_center < -100.0 (Out of bounds)")
			continue

		# [弱要求平整度校验] 探测 10x10 (半径5米) 范围内是否属于平地
		if not _is_area_relatively_flat(Vector3(random_x, h_center, random_z), 5.0, 3.0):
			_log_trace("Skip: Terrain too steep in 10x10 area.")
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
			var spawn_pos = Vector3.ZERO
			var valid = false
			# 在 Fallback 中也要确保坐标在合法地形范围内，否则会埋入无尽的边缘背景土里
			for attempt in range(50):
				var random_x = randf_range(-1500.0, 1500.0)
				var random_z = randf_range(-1500.0, 1500.0)
				spawn_pos = Vector3(random_x, 0.0, random_z)
				if terrain and "data" in terrain and terrain.data:
					var h = terrain.data.get_height(Vector3(random_x, 0, random_z))
					if not is_nan(h):
						spawn_pos.y = h
						valid = true
						break
			
			if not valid:
				_log_trace("Fallback failed to find valid height inside bounds! Skipping this sect.")
				continue

			_log_trace("Spawning fallback sect at: " + str(spawn_pos))
			generator.create_sect_at_location(spawn_pos, "")
			seeded_count += 1

	print("[WorldSectSeeder] 🌍 播种完毕！成功降世了 ", seeded_count, " 个初始宗门！修仙界开始运转！")
	_log_trace("=== FINISHED SEEDING ===")

## 探测以坐标为中心，指定半径的十字区域内地势是否相对平坦
## @param center_pos: 目标坐标 (Y 为中心地表高度)
## @param radius: 探测半径 (例如 5.0 代表 10x10 范围)
## @param max_tolerance: 容忍的最大落差
func _is_area_relatively_flat(center_pos: Vector3, radius: float = 5.0, max_tolerance: float = 3.0) -> bool:
	var cx = center_pos.x
	var cz = center_pos.z
	
	var h_center = center_pos.y
	var h_n = WorldGridManager.get_terrain_height(Vector3(cx, 0, cz - radius))
	var h_s = WorldGridManager.get_terrain_height(Vector3(cx, 0, cz + radius))
	var h_e = WorldGridManager.get_terrain_height(Vector3(cx + radius, 0, cz))
	var h_w = WorldGridManager.get_terrain_height(Vector3(cx - radius, 0, cz))
	
	var h_max = max(h_center, max(h_n, max(h_s, max(h_e, h_w))))
	var h_min = min(h_center, min(h_n, min(h_s, min(h_e, h_w))))
	
	# 如果存在超出边界点，安全起见认为是悬崖/非法
	if h_min < -100.0:
		return false
		
	return (h_max - h_min) <= max_tolerance
