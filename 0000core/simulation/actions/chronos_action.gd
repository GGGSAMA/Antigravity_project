extends Resource
class_name ChronosAction

# ==============================================================================
# 大一统行为基类 (ChronosAction)
# ==============================================================================
# 无论是玩家还是 NPC，修仙界的每一个特定行为（打坐、劫道、炼丹）都应继承此类。

@export var action_id: String = ""
@export var action_name: String = "未命名行为"
@export var is_long_term: bool = true # 是否属于长周期跨时活动

# ================================
# 1. 评估与决策 (AI 推演阶段使用)
# ================================
# 评估 actor 执行此行动的收益得分 (0-100)。
# 玩家无需调用此方法，AI 宏观推演时会遍历并取最高分执行。
func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0

# 是否可以开始此行为（例如：炼丹需要材料，打坐需要安全环境）
func can_execute(actor: ActorProxy) -> bool:
	return true

# ================================
# 2. 岁月演化结算 (核心推演逻辑)
# ================================
# 时序引擎切片推演时调用。
# hours_passed: 本次切片流逝了多少时间
func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	pass

# ================================
# 3. 互动结算 (交互逻辑)
# ================================
# 当行为涉及两个实体互相影响时调用 (如：劫道、双修)。
func resolve_interaction(actor: ActorProxy, target: ActorProxy) -> void:
	pass

# --------------------------------
# 便捷日志输出
# --------------------------------
func log_event(actor: ActorProxy, msg: String) -> void:
	if Engine.get_main_loop().root.has_node("ChronosEventLogManager"):
		var time = 0.0
		if Engine.get_main_loop().root.has_node("TimeManager"):
			time = Engine.get_main_loop().root.get_node("TimeManager").absolute_time_hours

		# 暂不细分 region_id
		Engine.get_main_loop().root.get_node("ChronosEventLogManager").add_event(time, "global", actor.get_name(), msg)
	else:
		print("[%s] %s" % [actor.get_name(), msg])
