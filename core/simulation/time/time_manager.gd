extends Node
class_name TimeManager_Core

# ==============================================================================
# 全局时间引擎 (Global Time Engine)
# 职责：维持世界唯一心跳，与物理帧解耦，支持极速倍速闭关流逝。
# ==============================================================================

signal on_day_passed(day: int)
signal on_month_passed(month: int)
signal on_year_passed(year: int)
signal on_time_skipped(years: int, days: int) # 极速结算核心信号
signal on_tick_log_generated(msg: String) # 用于向前台UI推送文字日志

var current_year: int = 1
var current_month: int = 1
var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0
var total_days_passed: int = 0

# 现实时间与游戏时间的比例 (例如: 现实 1 秒 = 游戏 1 分钟)
var time_scale_real_sec_to_game_min: float = 1.0
var _time_accumulator: float = 0.0

func _ready() -> void:
	print("[", Time.get_ticks_msec(), " ms] [TimeEngine] 全局时间轴初始化，修仙历 1年 1月 1日")

# ------------------------------------------------------------------------------
# 核心循环：日常自然流逝 (极慢)
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	# 自然时间流逝 (玩家在地图上发呆、走路时)
	_time_accumulator += delta
	if _time_accumulator >= (1.0 / time_scale_real_sec_to_game_min):
		_time_accumulator -= (1.0 / time_scale_real_sec_to_game_min)
		_advance_one_minute()

# ------------------------------------------------------------------------------
# 闭关极速结算 (Delta-Time Skip)
# ------------------------------------------------------------------------------
func start_closed_door_cultivation(years: int) -> void:
	on_tick_log_generated.emit("【系统】你开始了长达 " + str(years) + " 年的闭关...")
	
	# 瞬间触发全图 AI 宏观结算 (不走帧循环)
	on_time_skipped.emit(years, 0)
	
	# 瞬间推进历法
	current_year += years
	total_days_passed += years * 365
	
	on_tick_log_generated.emit("【系统】闭关结束。当前历法：" + get_date_string())

# ------------------------------------------------------------------------------
# 单日/单分逻辑推进
# ------------------------------------------------------------------------------
func _advance_one_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			_advance_one_day()

func _advance_one_day() -> void:
	current_day += 1
	total_days_passed += 1
	
	on_day_passed.emit(current_day)
	
	if current_day > 30:
		current_day = 1
		current_month += 1
		on_month_passed.emit(current_month)
		
		if current_month > 12:
			current_month = 1
			current_year += 1
			on_year_passed.emit(current_year)

func get_date_string() -> String:
	return str(current_year) + "年 " + str(current_month) + "月 " + str(current_day) + "日"
