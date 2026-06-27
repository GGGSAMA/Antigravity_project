extends Node

# ==============================================================================
# 【全局事务调度引擎 (Transaction Manager)】
# 职责：维护所有活跃/休眠事务单据池。配合 MacroSimulator 在闭关快进时批量串行推进。
# ==============================================================================

var active_tickets: Array[TransactionTicket] = []
var suspended_tickets: Array[TransactionTicket] = []

func _ready() -> void:
	if EventBus and EventBus.has_signal("level_changing"):
		EventBus.level_changing.connect(reset_state)

func reset_state() -> void:
	active_tickets.clear()
	suspended_tickets.clear()
	print("[TransactionManager] 状态已重置")

func submit_ticket(ticket: TransactionTicket) -> void:
	active_tickets.append(ticket)

# 由 TimeManager/MacroSimulator 驱动，分配时间切片
# 警告：探索模式下严禁挂载在 _process 调用此函数，必须锁死在闭关快进中！
func process_time_slice(time_skipped: float) -> void:
	# 1. 唤醒嗅探：尝试把搁置队列的单据重新丢回活跃队列
	if not suspended_tickets.is_empty():
		var newly_awaken: Array[TransactionTicket] = []
		var remain_suspended: Array[TransactionTicket] = []
		for t in suspended_tickets:
			# 简单唤醒逻辑：只要到了新的大时间切片，就给它一次重新 evaluate 的机会
			t.change_status(TransactionTicket.Status.PENDING, "闭关推演中...")
			newly_awaken.append(t)

		active_tickets.append_array(newly_awaken)
		suspended_tickets.clear()

	if active_tickets.is_empty():
		return

	# 2. 为了防止在遍历时修改数组，使用一个备份
	var current_batch = active_tickets.duplicate()
	active_tickets.clear()

	for ticket in current_batch:
		var time_left = time_skipped
		var finished = false

		while time_left > 0.05 and not finished:
			if ticket.current_step_index >= ticket.processors.size():
				# 所有处理层全数通过，落地生效
				_finalize_ticket(ticket, true)
				finished = true
				break

			var processor = ticket.processors[ticket.current_step_index]
			var result = processor.process(ticket, time_left)

			match result:
				StepProcessor.Result.PASS:
					ticket.current_step_index += 1
					# time_left 应当由 processor 内部去减，这里为了简化，我们假设 processor 瞬间通过或者扣除一部分
					# 真正的架构里，processor 应该返回消费的时间

				StepProcessor.Result.REJECT:
					# 中途否决，回滚并触发回执
					_finalize_ticket(ticket, false)
					finished = true
					break

				StepProcessor.Result.SUSPEND:
					# 搁置，放入休眠队列
					ticket.change_status(TransactionTicket.Status.SUSPENDED, "事务搁置")
					suspended_tickets.append(ticket)
					finished = true
					break

func _finalize_ticket(ticket: TransactionTicket, is_success: bool) -> void:
	if is_success:
		ticket.change_status(TransactionTicket.Status.COMPLETED, "圆满出关")
	else:
		ticket.change_status(TransactionTicket.Status.REJECTED, "重伤调息")

	# 反向回传触发回执 (从后往前调用 on_callback)
	for i in range(ticket.current_step_index - 1, -1, -1):
		var p = ticket.processors[i]
		p.on_callback(ticket, is_success)

	# TODO: 如果有对象池，在此处回收 ticket

# ==========================================
# 4. 全局存档存取 (Global Persistence)
# ==========================================
func serialize() -> Dictionary:
	var active = []
	for t in active_tickets: active.append(t.serialize())
	var suspended = []
	for t in suspended_tickets: suspended.append(t.serialize())

	return {
		"active_tickets": active,
		"suspended_tickets": suspended
	}

func deserialize(data: Dictionary) -> void:
	active_tickets.clear()
	suspended_tickets.clear()
	# 注：这里反序列化出来的 ticket 需要重新根据 transaction_type 初始化 Processors，
	# 因为 Processors 里可能有无状态的逻辑代码实例。此处简化为仅载入数据。
