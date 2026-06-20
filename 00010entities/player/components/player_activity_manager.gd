extends TimeNode
class_name PlayerActivityManager

var current_activity_id: String = ""
var _stats: Node
var _spells: Node

func _ready() -> void:
	granularity = TimeGranularity.MONTH # 玩家长时间交互一般按月/天计算收益
	priority = SettlePriority.PLAYER # 玩家结算优先级最低（在环境生态演化之后）
	
	super._ready() # 注册到 ChronosScheduler
	
	# 挂载在 Player 节点下，获取同级的 Stats 和 Spells 组件
	_stats = get_parent().get_node_or_null("Stats")
	_spells = get_parent().get_node_or_null("Spells")

var current_context: Dictionary = {}

# 开始一场长耗时活动 (由 UI 触发)
func start_activity(action_id: String, context: Dictionary = {}) -> void:
	current_activity_id = action_id
	current_context = context
	is_long_secluded_activity = true
	
	# 让玩家进入打坐动画等
	var parent = get_parent()
	if parent.has_method("play_animation"):
		parent.play_animation("idle") # TODO: 替换为真实的动画

func clear_activity() -> void:
	current_activity_id = ""
	current_context = {}
	is_long_secluded_activity = false

# 随岁月流逝结算玩家收益
func _on_time_advanced(hours_skipped: float) -> void:
	if current_activity_id == "":
		return
		
	if not Engine.get_main_loop().root.has_node("ActionLibrary"): return
	var action_lib = Engine.get_main_loop().root.get_node("ActionLibrary")
	var action = action_lib.get_action(current_activity_id)
	
	if action:
		var proxy = ActorProxy.new(get_parent())
		action.settle_time_chunk(proxy, hours_skipped)
	else:
		print("[PlayerActivityManager] 未找到注册的大一统行为: ", current_activity_id)
