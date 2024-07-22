#class_name class
extends GutTest


func test_log_count() -> void:
	# separate test in console
	var test_log_string := "testing log counting"
	GlobalLog.info(self, test_log_string)
	var initial_log_count := GlobalLog.total_log_calls
	GlobalLog.info(self, test_log_string)
	var updated_log_count := GlobalLog.total_log_calls
	assert_eq(updated_log_count, initial_log_count + 1)

