extends RefCounted
class_name AITestCase

# ==============================================================================
# AI-Native 测试断言基类 (AI-Native Test Assertion Base Class)
# ==============================================================================

var failure_reports: Array[Dictionary] = []
var pass_count: int = 0
var fail_count: int = 0

func setup() -> void:
	pass

func teardown() -> void:
	pass

func assert_eq(actual: Variant, expected: Variant, context_msg: String = "") -> bool:
	if actual == expected:
		pass_count += 1
		return true
	
	fail_count += 1
	var report = {
		"type": "assert_eq",
		"expected": expected,
		"actual": actual,
		"context": context_msg
	}
	failure_reports.append(report)
	return false

func assert_true(condition: bool, context_msg: String = "") -> bool:
	if condition:
		pass_count += 1
		return true
		
	fail_count += 1
	var report = {
		"type": "assert_true",
		"expected": true,
		"actual": condition,
		"context": context_msg
	}
	failure_reports.append(report)
	return false

func has_failures() -> bool:
	return failure_reports.size() > 0

func get_json_telemetry() -> String:
	return JSON.stringify(failure_reports, "\t")
