# ==============================================================================
# SectGenerator (宗门实体生成局)
# 
# [设计意图 / Design Intent]:
# 负责在指定的 3D 坐标处真正实例化出一个宗门的全部数据实体与阵眼建筑。
# 与播种机 (WorldSectSeeder) 仅仅勘探坐标不同，本模块负责向世界地块 (WorldGrid)
# 申请正式的势力领地，分配传送令牌，并实例化物理对象。
#
# [架构职责 / Responsibilities]:
# 1. 创建宗门数据档案 (FactionData)，随机生成宗门背景与特性 (LoreGenerator)。
# 2. 将数据注册到 FactionManager 中。
# 3. 在 3D 场景中实例化宗门阵眼 (SectCorePillar) 建筑。
# 4. 生成该宗门的专属传送令牌 (SectToken) 并尝试下发给创建者。
# ==============================================================================
extends Node
class_name SectGenerator

const FactionData = preload("res://0000core/000010_simulation/factions/faction_data.gd")
const LoreGenerator = preload("res://0000core/000010_simulation/entities/lore_generator.gd")

const SECT_TRAITS = ["剑道魁首", "万丹宝阁", "灵矿巨头", "好战狂人"]
const SECT_CORE_PILLAR = preload("res://00042world/architecture/sect_core_pillar.tscn")

func _log_trace(msg: String) -> void:
	var f = FileAccess.open("res://logs/game_full.log", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line("[%s] [SectGenerator] %s" % [Time.get_time_string_from_system(), msg])
		f.close()

## 在给定的世界坐标生成一个全新的宗门
## @param world_pos: 目标 3D 坐标
## @param creator_npc_id: (可选) 创建该宗门的 NPC 或玩家 ID
## @return: 返回新生成的宗门唯一 ID (String)
## @description:
## 内部会向 WorldGrid 申请 3x3 领地，一旦申请成功，才会实例化宗门阵眼建筑。
## 生成完成后，会立刻创建一个绑定该宗门的传送令牌，并分发给创建者（或掉落在阵眼旁）。
func create_sect_at_location(world_pos: Vector3, creator_npc_id: String = "") -> String:
	_log_trace("Creating sect at " + str(world_pos))
	var fm = get_parent()
	var new_sect_id = "sect_" + str(Time.get_ticks_usec())
	var faction = FactionData.new()
	faction.faction_id = new_sect_id
	faction.faction_name = LoreGenerator.generate_sect_name()
	faction.alignment = randi() % 3
	faction.level = 1
	faction.core_world_pos = world_pos
	faction.territory_radius = 128.0 

	faction.culture.traits.append(SECT_TRAITS.pick_random())

	faction.building.buildings["main_hall"] = 1
	faction.building.building_nodes.append({
		"type": "main_hall",
		"pos": world_pos,
		"rotation": randf() * TAU
	})

	# 优先同步获取地形真实高度，修正 faction.core_world_pos 防止 NPC 刷在地下
	var terrain = null
	if Engine.get_main_loop().root:
		terrain = Engine.get_main_loop().root.find_child("Terrain3D", true, false)
	if terrain and "data" in terrain and terrain.data:
		var h = terrain.data.get_height(Vector3(world_pos.x, 0, world_pos.z))
		if not is_nan(h):
			faction.core_world_pos.y = h + 0.1

	fm.active_factions[new_sect_id] = faction

	print("[FactionManager] ⛩️ 惊天动地！【", faction.faction_name, "】在坐标 ", faction.core_world_pos, " 正式开宗立派！")

	# ==========================================
	# 在3D世界中放置阵眼柱子实体
	# ==========================================
	_spawn_sect_core_pillar(faction.core_world_pos, faction.faction_name)

	var wgm = get_node_or_null("/root/WorldGridManager")
	if wgm:
		wgm.claim_territory_radius(world_pos, 4, new_sect_id) 

	var pop_spawner = fm.get_node_or_null("PopulationSpawner")
	if pop_spawner:
		pop_spawner.generate_initial_population(faction, creator_npc_id)

	# 【造物主特权】派发宗门专属传送令
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_node_or_null("/root/GameRoot/Player")

	if player:
		var inventory = player.get_node_or_null("Inventory")
		if inventory and inventory.has_method("add_item"):
			var token_data = {
				"affixes": {
					# 偏移传送坐标（向东南偏移 5 米），防止玩家刚好骑在柱子上或卡在柱子里面
					"teleport": [world_pos.x + 5.0, world_pos.y, world_pos.z + 5.0],
					"sect_name": faction.faction_name
				}
			}
			inventory.add_item("宗门传送令", 1, token_data)
			_log_trace("Created token with teleport: " + str(token_data.affixes.teleport))
			print("[SectGenerator] 🎟️ 已将【", faction.faction_name, "】的宗门传送令发放至造物主背包！")

	return new_sect_id

# ==========================================
# 在世界中实例化宗门阵眼柱
# ==========================================
func _spawn_sect_core_pillar(world_pos: Vector3, sect_name: String) -> void:
	var pillar = SECT_CORE_PILLAR.instantiate()
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(pillar)

	# 安全落地：优先使用真实地形高度 (避开物理碰撞未加载问题)
	var safe_pos = world_pos
	var terrain = null
	if Engine.get_main_loop().root:
		terrain = Engine.get_main_loop().root.find_child("Terrain3D", true, false)

	if terrain and "data" in terrain and terrain.data:
		var h = terrain.data.get_height(Vector3(world_pos.x, 0, world_pos.z))
		if not is_nan(h):
			safe_pos.y = h + 0.1
			_log_trace("Pillar safe_pos.y set from data: " + str(safe_pos.y))
		else:
			_log_trace("Pillar safe_pos.y from data was NaN, keeping world_pos: " + str(safe_pos.y))
	else:
		_log_trace("Terrain data unavailable. Falling back to raycast for Pillar.")
		# 兜底：从高空射线探测地面
		if scene_root:
			# 等一帧让物理世界更新
			await get_tree().physics_frame
			var space = pillar.get_world_3d().direct_space_state
			if space:
				var query = PhysicsRayQueryParameters3D.create(
					Vector3(world_pos.x, 200.0, world_pos.z),
					Vector3(world_pos.x, -100.0, world_pos.z)
				)
				query.exclude = [pillar.get_rid()]
				var result = space.intersect_ray(query)
				if not result.is_empty():
					safe_pos = result.position
					safe_pos.y += 0.1  # 微微抬起防止穿模
					_log_trace("Pillar raycast hit: " + str(safe_pos.y))
				else:
					_log_trace("Pillar raycast missed. Kept safe_pos: " + str(safe_pos.y))

	if scene_root:
		pillar.global_position = safe_pos
		_log_trace("Pillar final global_position: " + str(safe_pos))

		# 设置宗门名称标签
		var label = pillar.get_node_or_null("SectNameLabel")
		if label:
			label.text = "⛩ " + sect_name + " ⛩"

		print("[SectGenerator] 🏛️ 阵眼柱已矗立于 ", safe_pos, " — ", sect_name)
	else:
		print("[SectGenerator] ⚠️ 未找到场景根节点，阵眼柱无法放置！")
