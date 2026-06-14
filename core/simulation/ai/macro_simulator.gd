extends Node

var simulation_timer: Timer

signal macro_event_logged(msg: String)

func _ready() -> void:
	print("[MacroSimulator] 初始化后台 AI 演算引擎...")
	simulation_timer = Timer.new()
	simulation_timer.wait_time = 3.0
	simulation_timer.autostart = true
	simulation_timer.timeout.connect(_on_simulation_tick)
	add_child(simulation_timer)

func _on_simulation_tick() -> void:
	print("[MacroSimulator] --- 开始新一轮世界推演 ---")
	for npc in SocialManager.npc_attributes.values():
		var npc_data = npc as NPCData
		if not npc_data.is_alive:
			continue
			
		# 衰减需求 (以 1 个逻辑单位时间)
		npc_data.decay_needs(1.0)
		
		# 评估行为
		var actions = {
			"cultivate": MacroActions.evaluate_cultivate(npc_data),
			"hunt": MacroActions.evaluate_hunt(npc_data),
			"heal": MacroActions.evaluate_heal(npc_data),
			"social": MacroActions.evaluate_social(npc_data)
		}
		
		var best_action = ""
		var highest_score = -1.0
		
		for action in actions.keys():
			if actions[action] > highest_score:
				highest_score = actions[action]
				best_action = action
				
		var log_msg = ""
		match best_action:
			"cultivate":
				log_msg = MacroActions.execute_cultivate(npc_data)
				npc_data.current_action = "修炼"
			"hunt":
				log_msg = MacroActions.execute_hunt(npc_data)
				npc_data.current_action = "打猎"
			"heal":
				log_msg = MacroActions.execute_heal(npc_data)
				npc_data.current_action = "疗伤"
			"social":
				log_msg = MacroActions.execute_social(npc_data)
				npc_data.current_action = "社交"
		
		if log_msg != "":
			print("[MacroSimulator] ", log_msg)
			macro_event_logged.emit(log_msg)
