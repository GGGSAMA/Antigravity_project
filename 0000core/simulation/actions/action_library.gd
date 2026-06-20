extends Node

# ==============================================================================
# 大一统行为库 (ActionLibrary)
# ==============================================================================
# 注册全局可用的行为。NPC AI 和玩家均从此库中获取行为实例。

var _actions: Dictionary = {}

func _ready() -> void:
	print("[ActionLibrary] 正在加载大千世界万物行为法则...")
	_register_action(preload("res://0000core/simulation/actions/action_meditate.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_rob.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_heal.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_wander.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_social.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_gather.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_trade.gd").new())
	_register_action(preload("res://0000core/simulation/actions/action_seek_life.gd").new())
	# 未来可注册炼丹、双修、宗门战等行为

func _register_action(action: ChronosAction) -> void:
	if action and action.action_id != "":
		_actions[action.action_id] = action

func get_action(action_id: String) -> ChronosAction:
	if _actions.has(action_id):
		return _actions[action_id]
	return null

# 全局翻译：根据 ID 获取本地化动作名称（供 UI 和日志使用）
func get_action_name(action_id: String) -> String:
	if _actions.has(action_id):
		return _actions[action_id].action_name
	
	# 硬编码一些系统状态的回退翻译
	match action_id:
		"dead": return "身死道消"
		"soul_fleeing": return "元神出窍"
		"idle": return "闲置"
		_: return "未知(" + action_id + ")"



# NPC 评估最佳行为
func evaluate_best_action_for(actor: ActorProxy) -> ChronosAction:
	var best_action: ChronosAction = null
	var highest_score: float = -1.0
	
	for action in _actions.values():
		if action.can_execute(actor):
			var score = action.evaluate_utility(actor)
			if score > highest_score:
				highest_score = score
				best_action = action
				
	return best_action
