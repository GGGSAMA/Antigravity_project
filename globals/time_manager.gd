extends Node

# ==============================================================================
# TimeManager (绝对时间与岁月跳跃引擎)
# ==============================================================================

# 1 现实秒 = 1 游戏分钟 = (1.0 / 60.0) 游戏小时
# 这是正常游玩流速。大段的岁月流逝将通过 UI 调用 skip_time 来实现
const GAME_HOURS_PER_REAL_SECOND: float = 10.0 / 60.0 

# 核心变量：绝对游戏小时数 (从游戏开始累计)
var absolute_time_hours: float = 0.0

# 信号
signal time_ticked(delta_hours: float) # 用于持续性逻辑（如太阳月亮旋转）
signal time_skipped_macro(skipped_hours: float) # 用于触发闭关宏观结算（寿命、奴仆工资、灵田）
signal day_passed # 当跨过一个完整的 24 小时周期时触发

var _last_day_emitted: int = 0

func _process(delta: float) -> void:
	# 物理帧自然流逝
	var delta_hours = delta * GAME_HOURS_PER_REAL_SECOND
	_advance_time(delta_hours)
	time_ticked.emit(delta_hours)

func _advance_time(delta_hours: float) -> void:
	absolute_time_hours += delta_hours
	
	# 检查是否跨越了整天
	var current_day = get_current_day()
	if current_day > _last_day_emitted:
		var days_diff = current_day - _last_day_emitted
		_last_day_emitted = current_day
		for i in range(days_diff):
			day_passed.emit()

# ==============================================================================
# 闭关 / 岁月跳跃 (Macro Time-Skip Engine)
# ==============================================================================
func skip_time(hours_to_skip: float) -> void:
	if hours_to_skip <= 0:
		return
		
	# 瞬间增加时间
	_advance_time(hours_to_skip)
	
	# 触发宏观全服大结算 (交给别的系统如 Stats、灵田 去侦听这个信号并执行扣血/给钱)
	time_skipped_macro.emit(hours_to_skip)
	
	print("[TimeManager] 岁月如梭！玩家闭关跳跃了 %.2f 小时 (约 %.2f 天)。当前绝对时间: %.2f" % [hours_to_skip, hours_to_skip/24.0, absolute_time_hours])

# ==============================================================================
# 工具函数 (Helper Functions)
# ==============================================================================
func get_current_day() -> int:
	return int(floor(absolute_time_hours / 24.0))

func get_current_hour_of_day() -> float:
	return fmod(absolute_time_hours, 24.0)

# 返回格式化时间字符串，方便 UI 显示 (例如 "Day 5 - 14:30")
func get_formatted_time_string() -> String:
	var day = get_current_day()
	var current_hour = get_current_hour_of_day()
	var h = int(floor(current_hour))
	var m = int(floor(fmod(current_hour, 1.0) * 60.0))
	return "Day %d - %02d:%02d" % [day, h, m]
