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
	# 物理帧自然流逝 (如果正在闭关则暂停自然流逝)
	if _is_skipping_time: return

	var delta_hours = delta * GAME_HOURS_PER_REAL_SECOND
	_advance_time(delta_hours)

	# 推送微观时序 (Tick/Hour) 给 ChronosScheduler
	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		Engine.get_main_loop().root.get_node("ChronosScheduler").process_time_chunk(delta_hours)

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
# 统一入口：请求岁月跳跃 (区分短时与长时)
# 跨度 <= 24小时：瞬时同步结算，无进度条，无后台分片
# 跨度 > 24小时：进入异步线性分片推演，弹出读条
func request_time_skip(hours_to_skip: float, description: String = "岁月流逝...") -> void:
	if hours_to_skip <= 0: return

	if hours_to_skip <= 24.0:
		_skip_time_sync(hours_to_skip)
	else:
		skip_time_async(hours_to_skip, description)

# 短时即时推演
func _skip_time_sync(hours_to_skip: float) -> void:
	# 瞬间增加时间
	_advance_time(hours_to_skip)

	# 将时间块推送给 ChronosScheduler，严格按优先级与空间层级进行分发结算
	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		Engine.get_main_loop().root.get_node("ChronosScheduler").process_time_chunk(hours_to_skip)
	else:
		time_skipped_macro.emit(hours_to_skip) # Fallback

	print("[TimeManager] 短时岁月跳跃完成：%.2f 小时" % hours_to_skip)

var _is_skipping_time: bool = false
var _skip_ui_canvas: CanvasLayer
var _skip_progress: ProgressBar
var _skip_label: Label

# 异步岁月跳跃：提供黑屏遮罩与进度条读条体验，防止单帧卡死
func skip_time_async(hours_to_skip: float, description: String = "岁月流逝...") -> void:
	if hours_to_skip <= 0 or _is_skipping_time:
		return

	_is_skipping_time = true
	_show_skip_ui(description)

	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		Engine.get_main_loop().root.get_node("ChronosScheduler").begin_macro_skip()

	# 将目标时间切分为多次迭代，保证 UI 读条平滑且不卡死
	# 基础切片大小 720 小时 (1个月)，但如果跳跃时间极长 (例如 100 年)，动态调大切片，最多分 20 次。
	var chunk_size = max(720.0, hours_to_skip / 20.0)
	var remaining_hours = hours_to_skip
	var total_skipped = 0.0

	while remaining_hours > 0:
		var skip_chunk = min(remaining_hours, chunk_size)

		# 推进绝对时间
		_advance_time(skip_chunk)

		# 触发优先级链式时序推演
		if Engine.get_main_loop().root.has_node("ChronosScheduler"):
			Engine.get_main_loop().root.get_node("ChronosScheduler").process_time_chunk(skip_chunk)
		else:
			time_skipped_macro.emit(skip_chunk) # Fallback

		remaining_hours -= skip_chunk
		total_skipped += skip_chunk

		# 更新 UI
		if _skip_progress:
			_skip_progress.value = (total_skipped / hours_to_skip) * 100.0
			_skip_label.text = description + "\n已过去: " + str(int(total_skipped / 24.0)) + " 天"

		# 等待一帧，让渲染管线更新 UI，并释放主线程防止无响应
		await get_tree().process_frame

	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		Engine.get_main_loop().root.get_node("ChronosScheduler").end_macro_skip()

	print("[TimeManager] 异步岁月跳跃完成！总计跳跃了 %.2f 小时。" % hours_to_skip)
	_hide_skip_ui()
	_is_skipping_time = false

func _show_skip_ui(desc: String) -> void:
	if not _skip_ui_canvas:
		_skip_ui_canvas = CanvasLayer.new()
		_skip_ui_canvas.layer = 100 # 确保在最上层
		add_child(_skip_ui_canvas)

		var bg = ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0, 0, 0, 0.85) # 半透明黑色遮罩
		_skip_ui_canvas.add_child(bg)

		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
		vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
		bg.add_child(vbox)

		_skip_label = Label.new()
		_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_skip_label.add_theme_font_size_override("font_size", 24)
		vbox.add_child(_skip_label)

		_skip_progress = ProgressBar.new()
		_skip_progress.custom_minimum_size = Vector2(400, 30)
		_skip_progress.step = 0.1
		vbox.add_child(_skip_progress)

	_skip_label.text = desc + "\n已过去: 0 天"
	_skip_progress.value = 0.0
	_skip_ui_canvas.visible = true

func _hide_skip_ui() -> void:
	if _skip_ui_canvas:
		_skip_ui_canvas.visible = false

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
