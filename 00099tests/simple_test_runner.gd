extends SceneTree

# ==============================================================================
# Simple Test Runner for TDD
# Usage: godot --headless -s tests/simple_test_runner.gd
# ==============================================================================

var passed = 0
var failed = 0

func _init():
	print("===================================")
	print("Starting TDD Test Suite...")
	print("===================================")

	run_test_suite("res://00099tests/test_cultivation.gd")

	print("===================================")
	if failed > 0:
		print("[FAILED] Tests Passed: %d | Tests Failed: %d" % [passed, failed])
		quit(1)
	else:
		print("[SUCCESS] All %d Tests Passed!" % passed)
		quit(0)

func run_test_suite(path: String):
	var script = load(path)
	if not script:
		print("❌ Could not load test suite: ", path)
		failed += 1
		return

	var instance = script.new()
	var methods = instance.get_method_list()

	for method in methods:
		if method.name.begins_with("test_"):
			if instance.has_method("setup"):
				instance.setup()
				
			var result = instance.call(method.name)
			
			if instance.has_method("teardown"):
				instance.teardown()
			
			if instance.get("failure_reports") != null and instance.has_failures():
				failed += 1
				print("❌ FAIL: ", method.name)
				print("--- [AI TELEMETRY DUMP] ---")
				print(instance.get_json_telemetry())
				print("---------------------------")
				instance.failure_reports.clear() # clear for next test
			else:
				passed += 1
				print("✅ PASS: ", method.name)
