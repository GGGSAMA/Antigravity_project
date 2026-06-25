@tool
extends SceneTree

func _init() -> void:
	print("[Refactor] Starting Player Scene Refactor...")
	
	var scene_path = "res://00030entities/player/player.tscn"
	var scene = load(scene_path) as PackedScene
	if not scene:
		print("[Error] Failed to load ", scene_path)
		quit(1)
		return

	var root = scene.instantiate()
	var has_changes = false

	if not root.has_node("Equipment"):
		print("[Refactor] Adding Equipment...")
		var InventoryComponent = load("res://00030entities/player/components/inventory_comp.gd")
		var eq = InventoryComponent.new()
		eq.name = "Equipment"
		eq.size = 4
		root.add_child(eq)
		eq.owner = root
		has_changes = true

	if not root.has_node("Spells"):
		print("[Refactor] Adding Spells...")
		var SpellComponent = load("res://00030entities/player/components/spell_comp.gd")
		var spells = SpellComponent.new()
		spells.name = "Spells"
		root.add_child(spells)
		spells.owner = root
		has_changes = true

	if not root.has_node("ScannerComponent"):
		print("[Refactor] Adding ScannerComponent...")
		var ScannerComp = load("res://00030entities/player/components/scanner_component.gd")
		var scanner = ScannerComp.new()
		scanner.name = "ScannerComponent"
		root.add_child(scanner)
		scanner.owner = root
		has_changes = true

	if not root.has_node("SectBuilderComp"):
		print("[Refactor] Adding SectBuilderComp...")
		var SectBuilderComp = load("res://00030entities/player/components/sect_builder_comp.gd")
		var builder = SectBuilderComp.new()
		builder.name = "SectBuilderComp"
		root.add_child(builder)
		builder.owner = root
		has_changes = true

	if has_changes:
		var new_scene = PackedScene.new()
		new_scene.pack(root)
		var err = ResourceSaver.save(new_scene, scene_path)
		if err == OK:
			print("[Refactor] Successfully saved ", scene_path)
		else:
			print("[Error] Failed to save scene, error code: ", err)
	else:
		print("[Refactor] No changes needed. Scene already has these nodes.")

	quit(0)
