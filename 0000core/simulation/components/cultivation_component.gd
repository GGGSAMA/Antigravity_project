class_name CultivationComponent
extends Node

# ==============================================================================
# 【修为与境界核心数据组件 (Cultivation Component)】
# 整体功能：
#   维护角色的修仙境界、当前灵力（Qi）、以及是否卡在瓶颈期的核心状态。
# 状态设定：
#   - is_bottlenecked: 当修为达到当前境界上限时锁定，必须通过突破解锁。
# 核心接口：
#   - add_qi(amount): 增加修为，提供给外界系统（如打坐、吃丹药）解耦调用。
#   - attempt_breakthrough(): 尝试突破，处理成功率和概率。
# 权重参数扩展说明：
#   本组件暴露了基础修炼速度、基础突破耗时等 Inspector 参数。
#   【未来扩展预留】：未来可以结合 NPC 的个性（如 `diligence` 勤勉度）进行动态乘算调整。
# ==============================================================================

signal qi_changed(current: float, max_qi: float)
signal realm_advanced(new_realm: int, new_stage: int)
signal breakthrough_failed(penalty_amount: float)
signal reached_bottleneck()
signal request_player_minigame(realm: int, stage: int, base_chance: float, bonus_chance: float)

@export var cultivation_realm: int = 1
@export var cultivation_stage: int = 1
@export var current_qi: float = 0.0
@export var is_bottlenecked: bool = false

@export_group("Cultivation Weights (数据驱动参数)")
# 提示：未来的【性格系统】(如勤奋度) 可在读取这些基础值后，再乘以性格系数(0.5~1.5)进行二次修正。
@export var base_breakthrough_time_years: float = 0.5 # 基础突破耗时
@export var realm_time_multiplier: float = 1.5 # 每次大境界突破耗时增加倍率
@export var base_cultivation_speed: float = 100.0 # 基础修炼速度 (每年经验)

var max_qi_cache: float = 100.0

func _ready():
	_refresh_max_qi()

func _refresh_max_qi():
	var data = RealmDatabase.get_realm_data(cultivation_realm, cultivation_stage)
	if data.is_empty():
		return
	max_qi_cache = data["max_qi"]
	qi_changed.emit(current_qi, max_qi_cache)

# 全局时间引擎或打坐模块调用此接口发放修为
func add_qi(amount: float) -> void:
	add_qi_with_leftover(amount)

# 返回溢出的经验
func add_qi_with_leftover(amount: float) -> float:
	if is_bottlenecked:
		return amount

	var space = max_qi_cache - current_qi
	if amount >= space:
		current_qi = max_qi_cache
		is_bottlenecked = true
		qi_changed.emit(current_qi, max_qi_cache)
		reached_bottleneck.emit()
		return amount - space
	else:
		current_qi += amount
		qi_changed.emit(current_qi, max_qi_cache)
		return 0.0

# 玩家点击突破按钮或 AI 闭关时调用此接口，bonus_chance 由外界（阵法、他人赠送的丹药）动态提供
func attempt_breakthrough(is_player: bool = false, bonus_chance: float = 0.0) -> bool:
	if not is_bottlenecked:
		push_warning("未达到瓶颈，无法强行突破！")
		return false

	var data = RealmDatabase.get_realm_data(cultivation_realm, cultivation_stage)
	if data.is_empty():
		return false

	var base_chance = data["chance"]

	# ========================================================
	# 核心分流：玩家由操作小游戏决定生死，NPC 由数值与概率决定生死
	# ========================================================
	if is_player:
		print("[系统] 检测到玩家尝试突破！拉起雷劫阵法小游戏... (基础成功率: %.1f%%, 丹药阵法加成: %.1f%%)" % [base_chance*100, bonus_chance*100])
		request_player_minigame.emit(cultivation_realm, cultivation_stage, base_chance, bonus_chance)
		# 暂时挂起，等待小游戏回调调用 force_breakthrough_resolve
		return false

	var final_chance = clamp(base_chance + bonus_chance, 0.0, 1.0)
	var roll = randf()

	if roll <= final_chance:
		return force_breakthrough_resolve(true)
	else:
		return force_breakthrough_resolve(false)

# 强制结算突破结果（由内部掷骰子或外部玩家小游戏通关后回调）
func force_breakthrough_resolve(is_success: bool) -> bool:
	var data = RealmDatabase.get_realm_data(cultivation_realm, cultivation_stage)
	if is_success:
		var old_name = RealmDatabase.get_realm_name(cultivation_realm, cultivation_stage)
		cultivation_realm = data["next_realm"]
		cultivation_stage = data["next_stage"]
		current_qi = 0.0
		is_bottlenecked = false
		_refresh_max_qi()
		var new_name = RealmDatabase.get_realm_name(cultivation_realm, cultivation_stage)
		print("[天道法则] 恭喜！突破成功！从 [%s] 晋升至 [%s]" % [old_name, new_name])
		realm_advanced.emit(cultivation_realm, cultivation_stage)
		return true
	else:
		var penalty = max_qi_cache * 0.2 # 扣除 20% 根基
		current_qi -= penalty
		if current_qi < 0:
			current_qi = 0
		is_bottlenecked = false
		qi_changed.emit(current_qi, max_qi_cache)
		print("[天道法则] 突破失败！根基受损，散去修为 %d 点，且已走火入魔！" % penalty)
		breakthrough_failed.emit(penalty)
		return false

func get_realm_name() -> String:
	return RealmDatabase.get_realm_name(cultivation_realm, cultivation_stage)
