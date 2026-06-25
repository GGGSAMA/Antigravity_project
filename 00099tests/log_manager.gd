extends Node
class_name LogManager

# ==============================================================================
# 【独立开发者级 Log 系统】
# ------------------------------------------------------------------------------
# 借鉴大厂（分级、落盘）但简化为适合独立开发的单例。
# 支持写入 user://game_run.log，随时用文本编辑器查看，不弄脏控制台。
# ==============================================================================

enum Level {
	DEBUG,
	INFO,
	WARN,
	ERROR
}

var current_level: int = Level.DEBUG

var log_file_full: FileAccess
var log_file_error: FileAccess
var log_file_ai_trace: FileAccess # AI 专属的深层状态快照日志
var log_file_console: FileAccess

signal log_written(level_str: String, category: String, message: String, full_text: String)

func _ready():
	# 确保 logs 文件夹存在
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")

	# 打开分类日志文件
	log_file_full = FileAccess.open("res://logs/game_full.log", FileAccess.WRITE)
	log_file_error = FileAccess.open("res://logs/game_error.log", FileAccess.WRITE)
	log_file_ai_trace = FileAccess.open("res://logs/game_ai_trace.jsonl", FileAccess.WRITE)
	log_file_console = FileAccess.open("res://logs/game_console.log", FileAccess.WRITE)

	if log_file_full:
		info("System", "LogManager 初始化成功，开始分级记录日志。")
		ai_trace("System", "init", {"message": "AI-Trace Log Initialized in JSONL format."})
	else:
		print("无法创建日志文件!")

	log_written.connect(_on_log_written)

func _on_log_written(level_str: String, category: String, message: String, full_text: String):
	# 将日志输出到游戏原有的 DevConsole 中
	var dev_console = get_node_or_null("/root/DevConsole")
	if dev_console and dev_console.has_method("log_from_manager"):
		var color = "white"
		match level_str:
			"[DEBUG]": color = "gray"
			"[INFO]":  color = "green"
			"[WARN]":  color = "yellow"
			"[ERROR]": color = "red"
		dev_console.log_from_manager("[%s] %s" % [category, message], color)

func _exit_tree():
	info("System", "游戏关闭，停止记录日志。")
	if log_file_full: log_file_full.close()
	if log_file_error: log_file_error.close()
	if log_file_ai_trace: log_file_ai_trace.close()

func _write_log(level: int, category: String, message: String):
	if level < current_level:
		return

	var level_str = ""
	match level:
		Level.DEBUG: level_str = "[DEBUG]"
		Level.INFO:  level_str = "[INFO]"
		Level.WARN:  level_str = "[WARN]"
		Level.ERROR: level_str = "[ERROR]"

	var time_str = Time.get_time_string_from_system()
	var final_msg = "%s %s [%s] %s" % [time_str, level_str, category, message]

	# 输出到控制台
	if level >= Level.WARN:
		printerr(final_msg)
	else:
		print(final_msg)

	# 写入本地 TXT 文件
	if log_file_full:
		log_file_full.store_line(final_msg)
		log_file_full.flush()

	if level >= Level.INFO and log_file_console:
		log_file_console.store_line(final_msg)
		log_file_console.flush()

	if level >= Level.WARN and log_file_error:
		log_file_error.store_line(final_msg)
		log_file_error.flush()

	# 发送信号供游戏内控制台显示
	log_written.emit(level_str, category, message, final_msg)

# --- 对外暴露的便捷方法 ---
func debug(category: String, message: String):
	_write_log(Level.DEBUG, category, message)

func info(category: String, message: String):
	_write_log(Level.INFO, category, message)

func warn(category: String, message: String):
	_write_log(Level.WARN, category, message)

func error(category: String, message: String):
	_write_log(Level.ERROR, category, message)

# 专供 AI 读取的深层状态追踪日志（不输出到控制台，纯底层数据序列化）
func ai_trace(category: String, event_action: String, context_dict: Dictionary = {}):
	if log_file_ai_trace:
		var time_str = Time.get_time_string_from_system()
		var log_obj = {
			"timestamp": time_str,
			"category": category,
			"action": event_action,
			"context": context_dict
		}
		var json_str = JSON.stringify(log_obj)
		log_file_ai_trace.store_line(json_str)
		log_file_ai_trace.flush()
