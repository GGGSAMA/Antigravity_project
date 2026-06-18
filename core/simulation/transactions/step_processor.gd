class_name StepProcessor
extends RefCounted

# ==============================================================================
# 【事务分层处理器基类 (Step Processor)】
# ==============================================================================

# 返回给上游调度器的执行结果
enum Result {
	PASS,      # 通过本层，流转给下一层
	REJECT,    # 本层否决，整条事务立刻终止，触发反向回滚/补偿
	SUSPEND    # 资源/条件不足，本层暂停，存入休眠队列以后再跑
}

# 核心处理函数，子类重写
func process(ticket: TransactionTicket, time_delta: float) -> Result:
	return Result.PASS

# 反向回执函数（当事务失败时，或者成功时用于最终写入脏标记）
func on_callback(ticket: TransactionTicket, is_success: bool) -> void:
	pass

# 内部助手函数：获取发起者 NPC 数据
func _get_npc(npc_id: String):
	if Engine.get_main_loop().root.has_node("SocialManager"):
		var sm = Engine.get_main_loop().root.get_node("SocialManager")
		if sm.has_method("get_npc"):
			return sm.get_npc(npc_id)
	return null
