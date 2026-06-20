extends Node

# ==============================================================================
# 万物岁月事件日志中枢 (ChronosEventLogManager)
# ==============================================================================
# 专门负责大时间跨度跳跃（闭关）期间，记录、检索、归档全世界的生态演变日志。

const MAX_EVENT_COUNT: int = 2000

# 每一条日志是一个 Dictionary:
# {
#   "time_stamp": float (absolute_time_hours),
#   "region_id": String,
#   "entity_name": String,
#   "message": String
# }
var _event_logs: Array = []

func _ready() -> void:
	print("[ChronosEventLogManager] 岁月史书已开启。")

# 记录一条岁月大事件
func add_event(time_stamp: float, region_id: String, entity_name: String, message: String) -> void:
	var event = {
		"time_stamp": time_stamp,
		"region_id": region_id,
		"entity_name": entity_name,
		"message": message
	}
	_event_logs.append(event)
	
	if _event_logs.size() > MAX_EVENT_COUNT:
		_event_logs.pop_front() # 内存保护机制

# 获取某一段岁月期间发生的所有大事件
func get_events_in_range(start_time: float, end_time: float) -> Array:
	var result = []
	for event in _event_logs:
		if event["time_stamp"] >= start_time and event["time_stamp"] <= end_time:
			result.append(event)
	return result

# 按区域过滤事件
func get_events_by_region(region_id: String, start_time: float = 0.0, end_time: float = 999999999.0) -> Array:
	var result = []
	for event in _event_logs:
		if event["region_id"] == region_id and event["time_stamp"] >= start_time and event["time_stamp"] <= end_time:
			result.append(event)
	return result

# 暴露给 UI 格式化展示的快捷接口
func get_formatted_log_string(start_time: float, end_time: float) -> String:
	var events = get_events_in_range(start_time, end_time)
	if events.is_empty():
		return "这段岁月，大千世界风平浪静，古井无波。"
		
	var sb = ""
	for e in events:
		var days = int(e["time_stamp"] / 24.0)
		sb += "[Day %d] [%s] %s\n" % [days, e["entity_name"], e["message"]]
	return sb

# 归档/清空（例如回档或新开档）
func clear_events() -> void:
	_event_logs.clear()
