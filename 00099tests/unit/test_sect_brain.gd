extends "res://addons/gut/test.gd"

const FactionData = preload("res://0000core/simulation/factions/faction_data.gd")
const SectBrainAI = preload("res://0000core/simulation/factions/components/sect_brain_ai.gd")

func test_poor_sect_issues_gather_task():
	var faction = FactionData.new()
	faction.faction_name = "穷宗门"
	faction.power.resource_reserves = 100 # Below 500 threshold
	
	var brain = SectBrainAI.new()
	brain.evaluate_needs_and_dispatch_tasks(faction)
	
	assert_eq(faction.task_pool.size(), 1, "Should generate exactly 1 task.")
	
	var task = faction.task_pool[0]
	assert_eq(task.type, "gather", "The task should be a gather task.")
	assert_eq(task.target, "赤血草", "The target should be default herb.")

func test_rich_sect_ignores_gather():
	var faction = FactionData.new()
	faction.faction_name = "富宗门"
	faction.power.resource_reserves = 9000 # Way above 500 threshold
	
	var brain = SectBrainAI.new()
	brain.evaluate_needs_and_dispatch_tasks(faction)
	
	assert_eq(faction.task_pool.size(), 0, "Rich sect should not generate poor gather tasks.")
