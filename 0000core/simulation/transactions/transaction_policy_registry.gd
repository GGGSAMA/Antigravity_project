class_name TransactionPolicyRegistry
extends RefCounted

# ==============================================================================
# 【全局事务策略注册表 (Transaction Policy Registry)】
# 职责：提供统一的工厂方法，封装各个具体 Transaction Processor 的组装细节，
#       使发起事务的业务层（如 macro_actions.gd）无需导入具体的 Processor 类。
# ==============================================================================

const WanderProcessors = preload("res://0000core/simulation/transactions/processors/wander_processors.gd")
const HuntProcessors = preload("res://0000core/simulation/transactions/processors/hunt_processors.gd")
const CombatProcessors = preload("res://0000core/simulation/transactions/processors/combat_processors.gd")
const CultivateProcessors = preload("res://0000core/simulation/transactions/processors/cultivate_processors.gd")

static func build_ticket(initiator_id: String, transaction_type: String, context_overrides: Dictionary = {}) -> TransactionTicket:
	var processors: Array[StepProcessor] = []
	
	match transaction_type:
		"wander":
			processors.append(WanderProcessors.NeedProcessor.new())
			processors.append(WanderProcessors.RiskProcessor.new())
			processors.append(WanderProcessors.RewardProcessor.new())
		"hunt":
			processors.append(HuntProcessors.TargetSelectionProcessor.new())
			processors.append(HuntProcessors.CombatSimulationProcessor.new())
			processors.append(HuntProcessors.SettlementProcessor.new())
		"combat":
			processors.append(CombatProcessors.InitiationProcessor.new())
			processors.append(CombatProcessors.ResolutionProcessor.new())
			processors.append(CombatProcessors.LootProcessor.new())
		"cultivate":
			processors.append(CultivateProcessors.EnvProcessor.new())
			processors.append(CultivateProcessors.BreakthroughProcessor.new())
			processors.append(CultivateProcessors.GrowthProcessor.new())
		_:
			if Engine.get_main_loop().root.has_node("Log"):
				Engine.get_main_loop().root.get_node("Log").warn("Transaction", "未知的事务类型，创建了空策略单据：" + transaction_type)

	var ticket = TransactionTicket.new(initiator_id, transaction_type, processors)
	ticket.context.merge(context_overrides, true)
	return ticket
