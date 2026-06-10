# ==============================================================================
# 【随身小秘境（小洞天）数据驱动核心组件】
# ------------------------------------------------------------------------------
# 类说明：管理玩家随身小秘境（小洞天）的所有数据和生产算法。
#         支持洞天升级、灵气浓度调整、多设施生产（打坐、炼丹、种田、炼器）、
#         妖怪/灵兽工人指派、精力衰减与休息、以及独立的洞天仓库。
# ==============================================================================

extends Node
class_name MysticRealmComponent

# --- 核心静态配表数据 ---
const RECIPES: Dictionary = {
	"小还丹": {
		"ingredients": { "朱砂": 2, "聚灵草": 1 },
		"result": "小还丹",
		"result_qty": 1,
		"base_duration": 15.0 # 基础炼制时间（秒）
	},
	"聚灵散": {
		"ingredients": { "聚灵草": 3 },
		"result": "聚灵散",
		"result_qty": 1,
		"base_duration": 20.0
	}
}

const CROPS: Dictionary = {
	"聚灵草种子": {
		"result": "聚灵草",
		"result_qty": 3,
		"base_duration": 10.0 # 基础生长所需秒数
	},
	"朱砂草种子": {
		"result": "朱砂",
		"result_qty": 2,
		"base_duration": 18.0
	}
}

# --- 洞天核心状态属性 ---
@export var realm_name: String = "随身太玄洞天"
@export var realm_level: int = 1
@export var spiritual_energy: float = 1.0 # 灵气浓度系数，影响所有的生产速度

# 设施字典：存储每个设施的数据状态
var facilities: Dictionary = {}

# 工人字典：存储灵兽/妖怪的数据状态
var workers: Dictionary = {}

# 仓库字典：独立的洞天仓库，存储原材料与成品
var warehouse: Dictionary = {}

# 累计总修为（通过洞天挂机获取）
var realm_cultivation_exp: float = 0.0

func _ready() -> void:
	initialize_default_realm()

# --- 初始化默认洞天资产与演示数据 ---
func initialize_default_realm() -> void:
	# 1. 初始化洞天仓库库存（提供测试耗材）
	warehouse = {
		"聚灵草": 12,
		"朱砂": 8,
		"聚灵草种子": 5,
		"朱砂草种子": 5,
		"铁精": 2
	}
	
	# 2. 初始化核心生产设施
	facilities = {
		"meditation": {
			"name": "天极打坐蒲团",
			"level": 1,
			"multiplier": 1.0,
			"assigned_worker_id": ""
		},
		"alchemy": {
			"name": "九转紫金炉",
			"level": 1,
			"efficiency": 1.0,
			"current_recipe": "",
			"recipe_progress": 0.0, # 0.0 到 1.0 之间
			"assigned_worker_id": ""
		},
		"farming": {
			"name": "太清灵田",
			"level": 1,
			"max_plots": 4,
			"plots": [
				{ "seed_name": "", "growth": 0.0, "is_mature": false },
				{ "seed_name": "", "growth": 0.0, "is_mature": false },
				{ "seed_name": "", "growth": 0.0, "is_mature": false },
				{ "seed_name": "", "growth": 0.0, "is_mature": false }
			],
			"assigned_worker_id": ""
		},
		"crafting": {
			"name": "玄火炼器台",
			"level": 1,
			"efficiency": 1.0,
			"current_project": "",
			"project_progress": 0.0,
			"assigned_worker_id": ""
		}
	}
	
	# 3. 初始化默认灵兽与妖怪工人（预设核心属性与工作状态机）
	workers = {
		"worker_bunny": {
			"id": "worker_bunny",
			"name": "抱元兔",
			"species": "灵兽",
			"stamina": 100.0,
			"max_stamina": 100.0,
			"work_state": "idle", # "idle" (闲置), "alchemy" (炼丹), "farming" (种田), "meditating" (打坐), "resting" (休息)
			"efficiency_multiplier": 1.0,
			"skills": {
				"farming": 3,
				"alchemy": 1,
				"crafting": 1,
				"meditation": 2
			}
		},
		"worker_fox": {
			"id": "worker_fox",
			"name": "赤焰狐",
			"species": "妖怪",
			"stamina": 100.0,
			"max_stamina": 100.0,
			"work_state": "idle",
			"efficiency_multiplier": 1.25,
			"skills": {
				"farming": 1,
				"alchemy": 4,
				"crafting": 2,
				"meditation": 1
			}
		}
	}
	
	print("[MysticRealm] 随身小秘境初始化完成！默认设施已建立，演示工人已进入洞天。")

# --- 工人指派核心接口 ---
func assign_worker(worker_id: String, facility_id: String) -> bool:
	if not workers.has(worker_id):
		push_error("[MysticRealm] 未找到工人: " + worker_id)
		return false
	if not facilities.has(facility_id):
		push_error("[MysticRealm] 未找到设施: " + facility_id)
		return false
		
	var worker = workers[worker_id]
	var facility = facilities[facility_id]
	
	# 1. 检查工人当前是否有指派工作，若有则先解除
	unassign_worker(worker_id)
	
	# 2. 检查设施是否已被其他工人占用
	if facility["assigned_worker_id"] != "":
		var current_assigned_worker = facility["assigned_worker_id"]
		unassign_worker(current_assigned_worker)
		print("[MysticRealm] 设施 ", facility_id, " 已被占用，已自动将前任工人 ", current_assigned_worker, " 设为闲置。")
		
	# 3. 进行双向关联绑定
	worker["work_state"] = facility_id
	facility["assigned_worker_id"] = worker_id
	
	print("[MysticRealm] 成功指派工人 ", worker["name"], " 去执行 [", facility["name"], "] 任务！")
	return true

func unassign_worker(worker_id: String) -> void:
	if not workers.has(worker_id):
		return
	var worker = workers[worker_id]
	var prev_state = worker["work_state"]
	
	# 如果正在休息，跳过
	if prev_state == "resting" or prev_state == "idle":
		worker["work_state"] = "idle"
		return
		
	# 解除设施的工人关联
	if facilities.has(prev_state):
		facilities[prev_state]["assigned_worker_id"] = ""
		
	worker["work_state"] = "idle"
	print("[MysticRealm] 工人 ", worker["name"], " 的工作已解除，状态设为闲置。")

# 令工人休息恢复精力
func send_worker_to_rest(worker_id: String) -> void:
	if not workers.has(worker_id):
		return
	unassign_worker(worker_id)
	workers[worker_id]["work_state"] = "resting"
	print("[MysticRealm] 工人 ", workers[worker_id]["name"], " 已被送入庇护所进行打坐休息回复精力。")

# --- 生产设施交互接口 ---

# 启动炼丹配方
func start_alchemy(recipe_name: String) -> bool:
	if not RECIPES.has(recipe_name):
		print("[MysticRealm] 炼丹失败，不存在配方: ", recipe_name)
		return false
		
	var facility = facilities["alchemy"]
	facility["current_recipe"] = recipe_name
	facility["recipe_progress"] = 0.0
	print("[MysticRealm] 炼丹炉已配置配方: 【", recipe_name, "】，等待分派有精力的妖怪开炉炼制！")
	return true

# 作物播种
func plant_seed(plot_idx: int, seed_name: String) -> bool:
	var facility = facilities["farming"]
	var plots = facility["plots"] as Array
	
	if plot_idx < 0 or plot_idx >= plots.size():
		return false
		
	if plots[plot_idx]["seed_name"] != "":
		print("[MysticRealm] 灵田第 ", plot_idx + 1, " 格子已被占用！")
		return false
		
	# 检查洞天仓库是否有种子
	if get_warehouse_count(seed_name) <= 0:
		print("[MysticRealm] 播种失败，洞天仓库缺少种子: ", seed_name)
		return false
		
	# 扣除仓库种子，并播种
	remove_warehouse_item(seed_name, 1)
	plots[plot_idx]["seed_name"] = seed_name
	plots[plot_idx]["growth"] = 0.0
	plots[plot_idx]["is_mature"] = false
	
	print("[MysticRealm] 灵田第 ", plot_idx + 1, " 格成功播下种子: 【", seed_name, "】")
	return true

# 收获作物
func harvest_plot(plot_idx: int) -> bool:
	var facility = facilities["farming"]
	var plots = facility["plots"] as Array
	
	if plot_idx < 0 or plot_idx >= plots.size():
		return false
		
	var plot = plots[plot_idx]
	if plot["seed_name"] == "" or not plot["is_mature"]:
		print("[MysticRealm] 收获失败，该格子未成熟或无作物。")
		return false
		
	var seed_name = plot["seed_name"]
	if not CROPS.has(seed_name):
		return false
		
	var crop_data = CROPS[seed_name]
	var result_item = crop_data["result"]
	var qty = crop_data["result_qty"]
	
	# 加入洞天仓库
	add_warehouse_item(result_item, qty)
	
	# 重置该灵田格子状态
	plots[plot_idx] = { "seed_name": "", "growth": 0.0, "is_mature": false }
	
	print("[MysticRealm] 灵田第 ", plot_idx + 1, " 格收获成功！获得：【", result_item, " x ", qty, "】已存入洞天仓库！")
	return true

# --- 独立的仓库进出辅助逻辑 ---

func get_warehouse_count(item_id: String) -> int:
	return warehouse.get(item_id, 0)

func add_warehouse_item(item_id: String, qty: int) -> void:
	if warehouse.has(item_id):
		warehouse[item_id] += qty
	else:
		warehouse[item_id] = qty
	print("[MysticRealm仓库] 增加了 ", item_id, " x ", qty, "，当前库存: ", warehouse[item_id])

func remove_warehouse_item(item_id: String, qty: int) -> bool:
	var current = get_warehouse_count(item_id)
	if current < qty:
		return false
	warehouse[item_id] -= qty
	if warehouse[item_id] == 0:
		warehouse.erase(item_id)
	print("[MysticRealm仓库] 消耗了 ", item_id, " x ", qty, "，剩余库存: ", warehouse.get(item_id, 0))
	return true

# --- 核心时间步长结算（Tick 生产算法，支持在线/离线挂机收益） ---
func process_tick(delta: float) -> void:
	# 1. 遍历所有工人，更新精力、工作与休息状态
	for w_id in workers:
		var worker = workers[w_id]
		
		# 状态回复：若工人在休息，则恢复精力
		if worker["work_state"] == "resting":
			worker["stamina"] = min(worker["stamina"] + 6.0 * delta, worker["max_stamina"]) # 每秒回复 6 点精力
			if worker["stamina"] >= worker["max_stamina"]:
				worker["stamina"] = worker["max_stamina"]
				worker["work_state"] = "idle"
				print("[MysticRealm] 工人 ", worker["name"], " 精力完全充满，回到闲置状态。")
				
		# 状态消耗：若工人正在工作，需检查并扣减精力
		elif worker["work_state"] != "idle":
			# 如果精力耗尽，强制停止工作并设为闲置
			if worker["stamina"] <= 0.0:
				worker["stamina"] = 0.0
				var prev_work = worker["work_state"]
				unassign_worker(w_id)
				print("[MysticRealm] ⚠️ 警告：工人 ", worker["name"], " 已经精疲力竭，强制停止 [", prev_work, "] 任务！")

	# 2. 打坐设施挂机经验结算（修仙修为）
	var meditation_facility = facilities["meditation"]
	var meditator_id = meditation_facility["assigned_worker_id"]
	var base_exp_rate = 1.0 # 基础每秒修为加成
	if meditator_id != "":
		var worker = workers[meditator_id]
		if worker["stamina"] > 0:
			# 工人打坐获得经验
			worker["stamina"] = max(worker["stamina"] - 0.8 * delta, 0.0) # 打坐极缓慢消耗精力
			var skill_bonus = 1.0 + worker["skills"]["meditation"] * 0.15
			var exp_gain = base_exp_rate * skill_bonus * spiritual_energy * worker["efficiency_multiplier"] * delta
			realm_cultivation_exp += exp_gain
	else:
		# 无工人打坐时，玩家挂机获取极微弱基础修为
		realm_cultivation_exp += base_exp_rate * 0.1 * spiritual_energy * delta

	# 3. 炼丹炉状态结算
	var alchemy_facility = facilities["alchemy"]
	var alchemist_id = alchemy_facility["assigned_worker_id"]
	var recipe_name = alchemy_facility["current_recipe"]
	
	if alchemist_id != "" and recipe_name != "":
		var worker = workers[alchemist_id]
		var recipe = RECIPES[recipe_name]
		
		# 首先验证仓库中是否有足够的原料
		var has_ingredients = true
		for ing_id in recipe["ingredients"]:
			var cost = recipe["ingredients"][ing_id]
			if get_warehouse_count(ing_id) < cost:
				has_ingredients = false
				break
				
		if not has_ingredients:
			# 原料不足，暂停炼制，将炼丹炉置为无配方状态
			print("[MysticRealm] ⚠️ 炼丹中断！洞天仓库缺少炼制 【", recipe_name, "】 的原料。")
			alchemy_facility["current_recipe"] = ""
			alchemy_facility["recipe_progress"] = 0.0
		else:
			# 扣除工人精力，累加炼制进度
			worker["stamina"] = max(worker["stamina"] - 2.5 * delta, 0.0) # 炼制每秒消耗 2.5 精力
			var alchemy_skill = worker["skills"]["alchemy"]
			var skill_bonus = 1.0 + alchemy_skill * 0.2
			var duration_multiplier = 1.0 / recipe["base_duration"]
			
			# 进度累加
			var progress_step = duration_multiplier * skill_bonus * spiritual_energy * worker["efficiency_multiplier"] * delta
			alchemy_facility["recipe_progress"] += progress_step
			
			# 炼丹炉进度满 100% 结算成品
			if alchemy_facility["recipe_progress"] >= 1.0:
				# 扣除消耗品
				for ing_id in recipe["ingredients"]:
					var cost = recipe["ingredients"][ing_id]
					remove_warehouse_item(ing_id, cost)
					
				# 获得产出成品
				var result = recipe["result"]
				var qty = recipe["result_qty"]
				add_warehouse_item(result, qty)
				
				# 重置进度并显示提示
				alchemy_facility["recipe_progress"] = 0.0
				print("[MysticRealm] 🌟 炼丹大成功！妖怪 ", worker["name"], " 成功炼制了一炉 【", result, " x ", qty, "】并装入宝库！")

	# 4. 灵田生长状态结算
	var farming_facility = facilities["farming"]
	var farmer_id = farming_facility["assigned_worker_id"]
	var plots = farming_facility["plots"] as Array
	
	var farmer = null
	if farmer_id != "":
		farmer = workers[farmer_id]
		if farmer["stamina"] > 0:
			farmer["stamina"] = max(farmer["stamina"] - 1.8 * delta, 0.0) # 种田每秒消耗 1.8 精力

	# 结算每一个灵田网格格子
	for i in range(plots.size()):
		var plot = plots[i]
		if plot["seed_name"] != "" and not plot["is_mature"]:
			var crop_data = CROPS[plot["seed_name"]]
			var duration = crop_data["base_duration"]
			var growth_step = (1.0 / duration) * spiritual_energy
			
			# 如果有专门的农夫工人在照顾，则获得技能额外加速成长
			if farmer and farmer["stamina"] > 0:
				var farm_skill = farmer["skills"]["farming"]
				growth_step *= (1.0 + farm_skill * 0.25) * farmer["efficiency_multiplier"]
				
			plot["growth"] += growth_step * delta * 100.0 # 转换百分比表示
			if plot["growth"] >= 100.0:
				plot["growth"] = 100.0
				plot["is_mature"] = true
				print("[MysticRealm] 🌱 灵田第 ", i + 1, " 格的 【", crop_data["result"], "】 已经成熟了！快来收获吧！")

# 挂接物理帧 Tick，使能自动生产机制
func _process(delta: float) -> void:
	process_tick(delta)

# --- 调试面板：打印洞天所有详细状态 ---
func print_realm_status() -> String:
	var info = "\n========= ⛩️ " + realm_name + " (等级:" + str(realm_level) + ") 状态面板 =========\n"
	info += "🌌 当前挂机累积总修为: " + str(snapped(realm_cultivation_exp, 0.1)) + " EXP\n"
	info += "✨ 当前洞天灵气倍率: " + str(spiritual_energy) + "x\n"
	info += "--------------------------------------------------\n"
	info += "📦 洞天仓库储备:\n"
	if warehouse.is_empty():
		info += "  [仓库空空如也]\n"
	else:
		for item in warehouse:
			info += "  - " + item + " x " + str(warehouse[item]) + "\n"
	
	info += "--------------------------------------------------\n"
	info += "👥 洞天工人状态:\n"
	for w_id in workers:
		var w = workers[w_id]
		info += "  - " + w["name"] + " (" + w["species"] + ") [体力:" + str(snapped(w["stamina"], 0.1)) + "/" + str(w["max_stamina"]) + "] 状态: " + w["work_state"] + "\n"
		info += "    (种田级:" + str(w["skills"]["farming"]) + ", 炼丹级:" + str(w["skills"]["alchemy"]) + ")\n"
		
	info += "--------------------------------------------------\n"
	info += "⛩️ 设施状态:\n"
	for f_id in facilities:
		var f = facilities[f_id]
		info += "  - " + f["name"] + " (等级:" + str(f["level"]) + ") "
		if f_id == "alchemy":
			if f["current_recipe"] != "":
				info += "[炼制中: " + f["current_recipe"] + " 进度: " + str(snapped(f["recipe_progress"] * 100.0, 0.1)) + "%] "
			else:
				info += "[闲置] "
		elif f_id == "farming":
			var plots_str = ""
			for p_idx in range(f["plots"].size()):
				var p = f["plots"][p_idx]
				if p["seed_name"] != "":
					plots_str += " 格" + str(p_idx+1) + ":" + p["seed_name"] + "(" + str(snapped(p["growth"], 0.1)) + "%" + ("已熟" if p["is_mature"] else "") + ")"
				else:
					plots_str += " 格" + str(p_idx+1) + ":[空]"
			info += plots_str + " "
		info += "指派工: " + (f["assigned_worker_id"] if f["assigned_worker_id"] != "" else "无") + "\n"
		
	info += "=================================================="
	return info
