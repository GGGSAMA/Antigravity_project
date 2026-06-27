class_name TransactionTicket
extends RefCounted

# ==============================================================================
# 【大世界事务单据 (Transaction Ticket)】
# 职责：承载宏观长线行为的全部上下文，配合 TransactionManager 实现在时间长河中的流转。
# ==============================================================================

enum Status {
	PENDING,    # 待处理/进行中
	SUSPENDED,  # 搁置/休眠 (等条件满足或闭关时继续)
	COMPLETED,  # 成功完成 (正向回执)
	REJECTED    # 被中途否决 (反向回滚)
}

var ticket_id: String
var initiator_id: String        # 发起者 (NPC 或 宗门 ID)
var transaction_type: String    # 事务类型 (如 "wander_treasure")

var processors: Array[StepProcessor] = [] # 串行处理链
var current_step_index: int = 0

var status: Status = Status.PENDING
var context: Dictionary = {}    # 变更缓存与上下文记录，脏数据存放处

# 时间推演消耗记录
var time_spent_so_far: float = 0.0
var max_time_allowance: float = 0.0

func _init(_initiator_id: String = "", _type: String = "", _processors: Array[StepProcessor] = []):
	ticket_id = str(hash(Time.get_ticks_usec())) + "_" + _type
	initiator_id = _initiator_id
	transaction_type = _type
	processors = _processors

# ==========================================
# 2. 分段状态机双向绑定 (State Binding)
# ==========================================
func bind_state(new_state: String) -> void:
	if Engine.get_main_loop().root.has_node("SocialManager"):
		var sm = Engine.get_main_loop().root.get_node("SocialManager")
		var npc = sm.get_npc(initiator_id)
		if npc:
			npc.current_action = new_state

func change_status(new_status: Status, state_label: String = "") -> void:
	status = new_status
	if state_label != "":
		bind_state(state_label)

# ==========================================
# 3. 持久化存档 (Persistence)
# ==========================================
func serialize() -> Dictionary:
	return {
		"ticket_id": ticket_id,
		"initiator_id": initiator_id,
		"transaction_type": transaction_type,
		"current_step_index": current_step_index,
		"status": status,
		"context": context,
		"time_spent_so_far": time_spent_so_far
	}

# 注意：反序列化时，处理链 (processors) 必须由 TransactionManager 负责根据 type 重新装配！
func deserialize(data: Dictionary) -> void:
	ticket_id = data.get("ticket_id", "")
	initiator_id = data.get("initiator_id", "")
	transaction_type = data.get("transaction_type", "")
	current_step_index = data.get("current_step_index", 0)
	status = data.get("status", Status.PENDING)
	context = data.get("context", {})
	time_spent_so_far = data.get("time_spent_so_far", 0.0)
