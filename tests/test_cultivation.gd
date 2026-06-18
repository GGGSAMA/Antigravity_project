extends RefCounted

const FactionData = preload("res://core/simulation/factions/faction_data.gd")
const SectBrainAI = preload("res://core/simulation/factions/components/sect_brain_ai.gd")

func test_sect_brain_generates_gather_task_when_poor() -> bool:
	# Arrange (Given)
	var faction = FactionData.new()
	faction.faction_id = "test_sect"
	faction.faction_name = "Test Sect"
	faction.power.resource_reserves = 100 # Poor sect, below 500 threshold
	
	var brain = SectBrainAI.new()
	
	# Act (When)
	brain.evaluate_needs_and_dispatch_tasks(faction)
	
	# Assert (Then)
	if faction.task_pool.size() != 1:
		print("  Expected 1 task, got ", faction.task_pool.size())
		return false
		
	var task = faction.task_pool[0]
	if task.get("type") != "gather":
		print("  Expected task type 'gather', got ", task.get("type"))
		return false
		
	return true

func test_sect_brain_ignores_rich_sects() -> bool:
	# Arrange
	var faction = FactionData.new()
	faction.power.resource_reserves = 1000 # Rich sect
	var brain = SectBrainAI.new()
	
	# Act
	brain.evaluate_needs_and_dispatch_tasks(faction)
	
	# Assert
	if faction.task_pool.size() != 0:
		print("  Expected 0 tasks, got ", faction.task_pool.size())
		return false
		
	return true
