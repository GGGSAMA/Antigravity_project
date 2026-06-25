extends AITestCase

const FactionData = preload("res://0000core/simulation/factions/faction_data.gd")
const SectBrainAI = preload("res://0000core/simulation/factions/components/sect_brain_ai.gd")

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
	var size_ok = assert_eq(faction.task_pool.size(), 1, "Expected 1 gather task to be generated for poor sect")
	if not size_ok: return false

	var task = faction.task_pool[0]
	return assert_eq(task.get("type"), "gather", "Task type should be gather")

func test_sect_brain_ignores_rich_sects() -> bool:
	# Arrange
	var faction = FactionData.new()
	faction.power.resource_reserves = 1000 # Rich sect
	var brain = SectBrainAI.new()

	# Act
	brain.evaluate_needs_and_dispatch_tasks(faction)

	# Assert
	return assert_eq(faction.task_pool.size(), 0, "Rich sects should not generate gather tasks automatically")
