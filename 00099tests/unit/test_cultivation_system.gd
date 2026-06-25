extends "res://addons/gut/test.gd"

const CultivationComponent = preload("res://0000core/simulation/components/cultivation_component.gd")

func test_add_qi_below_max():
	var comp = CultivationComponent.new()
	comp.cultivation_realm = 1
	comp.cultivation_stage = 1
	comp.max_qi_cache = 100.0
	comp.current_qi = 10.0

	comp.add_qi(20.0)

	assert_eq(comp.current_qi, 30.0, "Qi should accumulate normally below max capacity.")
	assert_false(comp.is_bottlenecked, "Should not hit bottleneck if max qi is not reached.")

func test_add_qi_hits_bottleneck():
	var comp = CultivationComponent.new()
	comp.cultivation_realm = 1
	comp.cultivation_stage = 1
	comp.max_qi_cache = 100.0
	comp.current_qi = 90.0

	# Attempt to add 50 Qi, which should overflow
	comp.add_qi(50.0)

	assert_eq(comp.current_qi, 100.0, "Qi should be capped at max_qi.")
	assert_true(comp.is_bottlenecked, "Should be bottlenecked after hitting max qi.")

func test_breakthrough_clears_bottleneck():
	var comp = CultivationComponent.new()
	comp.cultivation_realm = 1
	comp.cultivation_stage = 1
	comp.is_bottlenecked = true

	comp.attempt_breakthrough(1.0) # Assume 100% chance for test

	assert_false(comp.is_bottlenecked, "Breakthrough should clear the bottleneck flag.")
