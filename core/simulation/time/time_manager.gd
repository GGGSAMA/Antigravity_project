extends Node
class_name TimeManager_Core

# ==============================================================================
# 全局时间引擎 (Global Time Engine)
# 职责：维持世界唯一心跳，与物理帧解耦，支持极速倍速闭关流逝。
# ==============================================================================

signal on_day_passed(day: int)
signal on_month_passed(month: int)
signal on_year_passed(year: int)
signal on_tick_log_generated(msg: String) # 用于向前台UI推送文字日志

var current_year: int = 1
var current_month: int = 1
var current_day: int = 1
var total_days_passed: int = 0

# 倍速控制
var is_fast_forwarding: bool = false
var days_to_skip: int = 0
var days_skipped_so_far: int = 0

func _ready() -> void:
	print("[TimeEngine] 全局时间轴初始化，修仙历 1年 1月 1日")

# ------------------------------------------------------------------------------
# 核心循环：支持分帧极速运算，不卡顿
# ------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if is_fast_forwarding and days_to_skip > 0:
		# 每一帧处理一定数量的天数（控制单帧开销，避免卡死）
		# 比如一帧算 30 天，一秒 60 帧就能算 1800 天（约 5 年），速度极快且不掉帧
		var batch_size = min(30, days_to_skip) 
		for i in range(batch_size):
			_advance_one_day()
			days_to_skip -= 1
			days_skipped_so_far += 1
			
		if days_to_skip <= 0:
			_stop_fast_forward()

func start_closed_door_cultivation(years: int) -> void:
	days_to_skip = years * 365
	days_skipped_so_far = 0
	is_fast_forwarding = true
	on_tick_log_generated.emit("【系统】你开始了长达 " + str(years) + " 年的闭关...")

func _stop_fast_forward() -> void:
	is_fast_forwarding = false
	on_tick_log_generated.emit("【系统】闭关结束，共度过 " + str(days_skipped_so_far) + " 天。当前历法：" + get_date_string())

func interrupt_cultivation(reason: String) -> void:
	if not is_fast_forwarding: return
	is_fast_forwarding = false
	days_to_skip = 0
	on_tick_log_generated.emit("【突发事件】" + reason)
	on_tick_log_generated.emit("【系统】你被迫强行出关！")

# ------------------------------------------------------------------------------
# 单日逻辑推进
# ------------------------------------------------------------------------------
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
