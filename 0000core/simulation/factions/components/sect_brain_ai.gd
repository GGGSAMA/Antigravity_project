extends Node
class_name SectBrainAI

const FactionData = preload("res://0000core/simulation/factions/faction_data.gd")

func evaluate_needs_and_dispatch_tasks(faction: FactionData) -> void:
	if faction.power.resource_reserves < 500:
		var has_gather = false
		for task in faction.task_pool:
			if task.get("type") == "gather":
				has_gather = true
				break
		if not has_gather:
			var task = {
				"task_id": "task_" + str(Time.get_ticks_usec()),
				"type": "gather",
				"target": "赤血草",
				"reward": 20, 
				"taken_by": ""
			}
			faction.task_pool.append(task)
			print("[SectBrainAI] ", faction.faction_name, " 资源紧缺！发布了悬赏任务: 采集赤血草！")
