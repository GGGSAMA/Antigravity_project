extends Node
class_name TimeNode

# ==============================================================================
# 万物岁月驱动通用基类 (TimeNode)
# ==============================================================================
# 任何需要响应大世界时间流逝的实体，都必须挂载此组件，或继承此类。
# 提供独立流速、分层优先级注册等核心功能。

enum TimeGranularity {
	TICK = 0,    # 细粒度，微观战斗/特效
	HOUR = 1,    # 日常杂役、移动
	MONTH = 2,   # 野怪生长、资源再生
	YEAR = 3     # 寿元衰减、宗门大盘、遗迹开启
}

enum SettlePriority {
	FOUNDATION = 0, # 天地灵气、世界阵法
	ECOLOGY = 1,    # 怪物刷新、草药成熟、遗迹开启
	SOCIETY = 2,    # 宗门推演、NPC宏观行为
	SERVANTS = 3,   # 傀儡/药童定点结算
	PLAYER = 4      # 玩家最终结算
}

@export_group("时空法则配置 (Chronos Rules)")
@export var granularity: TimeGranularity = TimeGranularity.MONTH
@export var priority: SettlePriority = SettlePriority.ECOLOGY

# 局部时间流速，默认为 1.0 (与大世界同步)。
# 若为 10.0，则外界过去 1 年，此节点内部度过 10 年。
@export var local_time_scale: float = 1.0 

@export_group("闭关与时空隔离 (Seclusion Isolation)")
# 核心字段：标记该实体是否处于绝对闭关状态。为 true 时，外部一切随机交互、寻仇、战斗判定都会将其跳过。
@export var is_long_secluded_activity: bool = false
var bound_long_action_id: String = ""
var last_settlement_time: float = 0.0

var _accumulated_hours: float = 0.0

func _ready() -> void:
	# 向全局调度中心注册
	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		var chronos = Engine.get_main_loop().root.get_node("ChronosScheduler")
		if chronos.has_method("register_node"):
			chronos.register_node(self)
	elif get_tree().root.has_node("ChronosScheduler"):
		get_tree().root.get_node("ChronosScheduler").register_node(self)

func _exit_tree() -> void:
	if Engine.get_main_loop().root.has_node("ChronosScheduler"):
		var chronos = Engine.get_main_loop().root.get_node("ChronosScheduler")
		if chronos.has_method("unregister_node"):
			chronos.unregister_node(self)
	elif get_tree().root.has_node("ChronosScheduler"):
		get_tree().root.get_node("ChronosScheduler").unregister_node(self)

# 由 ChronosScheduler 根据优先级队列调用
# chunk_hours_passed: 本次跳跃的时长 (大世界时长)
func process_time_chunk(chunk_hours_passed: float) -> void:
	# 1. 获取全局区块流速 (TimeZone Scale)
	var zone_scale = 1.0
	if Engine.get_main_loop().root.has_node("WorldGridManager"):
		var wgm = Engine.get_main_loop().root.get_node("WorldGridManager")
		if wgm.has_method("get_tile_at_world_pos"):
			var pos = Vector3.ZERO
			if get_parent() is Node3D:
				pos = get_parent().global_position

			if pos != Vector3.ZERO:
				var tile = wgm.get_tile_at_world_pos(pos)
				if tile and "time_zone_scale" in tile:
					zone_scale = tile.time_zone_scale

	# 2. 局部流速叠加
	var scaled_hours = chunk_hours_passed * local_time_scale * zone_scale
	_accumulated_hours += scaled_hours

	# 过滤逻辑：是否满足粒度要求？
	var threshold = 0.0
	match granularity:
		TimeGranularity.TICK: threshold = 0.0
		TimeGranularity.HOUR: threshold = 1.0
		TimeGranularity.MONTH: threshold = 720.0
		TimeGranularity.YEAR: threshold = 8640.0

	if _accumulated_hours >= threshold:
		_on_time_advanced(_accumulated_hours)
		_accumulated_hours = 0.0

# ------------------------------------------------------------------------------
# 虚方法：子类必须重写此方法来实现具体的岁月沉淀逻辑
# ------------------------------------------------------------------------------
func _on_time_advanced(delta_hours: float) -> void:
	pass
