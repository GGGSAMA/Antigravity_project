# ==============================================================================
# 【Godot 核心架构类：角色状态组件（CharacterStats）】
# ------------------------------------------------------------------------------
# 牢大（用户）需求档案：修仙点卡机制（时间经济学）
# 1. 灵石产出：挂机/现实时间流逝 = 自动产出灵石。
# 2. 灵力恢复：当灵力不满时，燃烧灵石转换为灵力（受“资质 aptitude”属性加成）。
# 3. 灵力消耗：施法、神识扫描（V键）等均消耗灵力。灵力枯竭则无法行动。
# 4. 全局组件：此组件可挂载于玩家、NPC 或怪物，作为数值运算的数据中心。
#
# 【AI 建议】：
# - 当前为 1秒 = 1灵石，测试期没问题。后续建议按真实修仙设定，改为“聚灵阵”环境下产出效率翻倍，
#   或者离线挂机时根据闭关时长一次性结算灵石。
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
var time_accumulator: float = 0.0


func recalculate() -> void:
	# 动态属性换算公式
	max_health = 100 + constitution * 10 + aptitude * 2
	max_mana = 100 + divine_sense * 15 + aptitude * 3
	
	# 安全边界限值校验
	current_health = clamp(current_health, 0, max_health)
	current_mana = clamp(current_mana, 0, max_mana)

func _ready() -> void:
	recalculate()
	# 按比例初始化当前生命与元气（留出空间方便拾取药水/加点测试回复）
	current_health = int(max_health * 0.8)
	current_mana = int(max_mana * 0.4)
	
	# 初始化时，延迟一帧广播一次当前血量和灵力，确保 UI 已经就绪并连上信号
	await get_tree().process_frame
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	spirit_stones_changed.emit(spirit_stones)

func _process(delta: float) -> void:
	time_accumulator += delta
	# 核心经济循环：现实时间 -> 灵石 -> 灵力
	if time_accumulator >= 1.0:
		time_accumulator -= 1.0
		# 1. 随着时间修行，自动产出灵石（类似点卡时间）
		spirit_stones += 1
		spirit_stones_changed.emit(spirit_stones)
		
		# 2. 如果灵力不满，消耗灵石补充灵力
		if current_mana < max_mana and spirit_stones > 0:
			spirit_stones -= 1
			spirit_stones_changed.emit(spirit_stones)
			restore_mana(2 + int(aptitude * 0.5)) # 资质影响转换效率


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


func get_speed_multiplier() -> float:
	return 1.0 + float(speed - 10) * 0.05

func get_interaction_range() -> float:
	return 2.5 + float(divine_sense - 10) * 0.15
