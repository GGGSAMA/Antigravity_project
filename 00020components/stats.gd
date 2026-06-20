# ==============================================================================
# 【Godot 核心架构类：角色状态组件（CharacterStats）】
# ------------------------------------------------------------------------------
# 牢大（用户）需求档案：修仙时间与点卡经济学
# 1. 寿命系统：引入 `age` 和 `max_age`，这是所有经济活动的最终天花板。
# 2. 灵力与时间锚定：不再按现实秒数自动回蓝。回蓝必须通过 `TimeManager` 进行岁月跳跃（打坐闭关）来实现，强行扣除对应比例的寿命。
# 3. 灵力消耗：所有动作（跑图、采药、战斗）均消耗灵力。
# ==============================================================================

extends Node
class_name CharacterStats # 注册为全局类，方便其他脚本进行类型强检查

# --- 信号声明（解耦的核心：观察者模式） ---
# 当生命值改变时向外广播。父节点（如玩家、怪物）去监听它，并决定如何展现（如更新 HUD）。
signal health_changed(current_health: int, max_health: int)
# 当灵力值改变时向外广播。
signal mana_changed(current_mana: int, max_mana: int)
# 当灵石值改变时向外广播。
signal spirit_stones_changed(current: int)


# --- 属性变量 ---
@export_group("五行先天灵根")
@export var root_gold: int = 20
@export var root_wood: int = 20
@export var root_water: int = 20
@export var root_fire: int = 20
@export var root_earth: int = 20

@export_group("修仙凡身根基")
@export var comprehension: int = 10 # 悟性
@export var aptitude: int = 10      # 资质
@export var constitution: int = 10  # 体力
@export var strength: int = 10      # 力量
@export var speed: int = 100         # 速度
@export var divine_sense: int = 10  # 神识

@export var max_health: int = 100
var current_health: int = 80 # 故意设为80，方便测试拾取加血！

@export var max_mana: int = 100
var current_mana: int = 40 # 故意设为40，方便测试回蓝！

@export var spirit_stones: int = 0

@export_group("岁月与寿元")
@export var age_days: float = 0.0          # 当前年龄（天数）
@export var max_age_days: float = 36500.0  # 寿元大限（默认 100年 = 36500天）
signal lifespan_changed(current_days: float, max_days: float)
signal character_died_of_old_age


func recalculate() -> void:
	# 动态属性换算公式
	max_health = 100 + constitution * 10 + aptitude * 2
	max_mana = 100 + divine_sense * 15 + aptitude * 3
	
	# 安全边界限值校验
	current_health = clamp(current_health, 0, max_health)
	current_mana = clamp(current_mana, 0, max_mana)

func _ready() -> void:
	recalculate()
	# 按比例初始化当前生命与元气
	current_health = int(max_health * 0.8)
	current_mana = int(max_mana * 0.4)
	
	# 初始化时，延迟一帧广播
	await get_tree().process_frame
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	spirit_stones_changed.emit(spirit_stones)
	lifespan_changed.emit(age_days, max_age_days)
	
	# 监听宏观岁月跳跃信号 (只有玩家或者常驻 NPC 需要，普通的怪物其实不需要监听闭关，这里简化处理全监听)
	if TimeManager:
		TimeManager.time_skipped_macro.connect(_on_time_skipped_macro)

func _on_time_skipped_macro(hours_skipped: float) -> void:
	# 1. 扣除寿命 (1 天 = 24 小时)
	var days_skipped = hours_skipped / 24.0
	age_days += days_skipped
	lifespan_changed.emit(age_days, max_age_days)
	
	# 检查是否老死
	if age_days >= max_age_days:
		character_died_of_old_age.emit()
		print("【天道无情】玩家大限已至，身死道消！")
		return
		
	# 具体的行为结算（打坐回蓝、参悟功法等）已全部移交至 PlayerActivityManager。
	# 这里只做基础状态的随岁月流失处理（如饱食度降低，当前版本不开启）

func _process(delta: float) -> void:
	pass # 移除了早期的按现实秒自动回蓝逻辑，现在的回蓝全靠宏观岁月跳跃



# --- 属性操作方法（API） ---
func heal(amount: int) -> void:
	var old_health = current_health
	current_health = clamp(current_health + amount, 0, max_health)
	
	# 如果数值真的改变了，发出广播
	if current_health != old_health:
		health_changed.emit(current_health, max_health)
		
		# 打印底层数值变更，用于测试验证
		print("【数据中心】", get_parent().name, " 生命值变更：", old_health, " -> ", current_health, "/", max_health)

func damage(amount: int) -> void:
	var old_health = current_health
	current_health = clamp(current_health - amount, 0, max_health)
	
	# 如果数值真的改变了，发出广播
	if current_health != old_health:
		health_changed.emit(current_health, max_health)
		
		# 打印底层数值变更，用于测试验证
		print("【数据中心】", get_parent().name, " 生命值变更：", old_health, " -> ", current_health, "/", max_health)


func restore_mana(amount: int) -> void:
	var old_mana = current_mana
	current_mana = clamp(current_mana + amount, 0, max_mana)
	
	# 如果数值真的改变了，发出广播
	if current_mana != old_mana:
		mana_changed.emit(current_mana, max_mana)
		# 暂不打印，避免每秒刷屏

func consume_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

# --- 修为与境界提升 (Cultivation & Breakthrough) ---
signal cultivation_changed(current: int, max_val: int)
signal breakthrough_achieved(new_level: int)

@export var cultivation_level: int = 1
var cultivation_points: int = 0
var max_cultivation: int = 100

func gain_cultivation(amount: int) -> void:
	cultivation_points += amount
	
	while cultivation_points >= max_cultivation:
		cultivation_points -= max_cultivation
		_breakthrough()
		
	cultivation_changed.emit(cultivation_points, max_cultivation)

func _breakthrough() -> void:
	cultivation_level += 1
	max_cultivation = int(max_cultivation * 1.5 + 100) # 突破难度递增
	
	# 核心属性成长
	constitution += 5
	divine_sense += 5
	aptitude += 2
	
	# 重新计算生命法力上限，并瞬间补满状态 (修仙大突破的效果)
	recalculate()
	heal(max_health)
	restore_mana(max_mana)
	
	breakthrough_achieved.emit(cultivation_level)
	
	print("【境界突破】当前境界：", cultivation_level, " 最大生命：", max_health, " 最大法力：", max_mana)


func get_speed_multiplier() -> float:
	return 1.0 + float(speed - 10) * 0.05

func get_interaction_range() -> float:
	return 2.5 + float(divine_sense - 10) * 0.15
