extends GutTest

# checks if the log call and log count increments correctly on various log types
# specifically excludes Log.critical calls as those will crash the
#	debugger - test that functionality manually

##############################################################################

# add any #//TODO here

##############################################################################

# test-scoped variants here

##############################################################################

# tests

# test if log call is incrementing even without output/registration
func test_log_calls() -> void:
	# no need to record or log spam when testing calls
	Log.allow_log_output = false
	Log.allow_log_registration = false
	var test_log_string := "testing log counting"
	
	var pre_test_log_count := Log.total_log_calls
	var expected_post_test_log_count = pre_test_log_count + 1
	Log.info(self, test_log_string)
	var updated_log_count := Log.total_log_calls
	assert_eq(updated_log_count, expected_post_test_log_count)
	
	pre_test_log_count = Log.total_log_calls
	expected_post_test_log_count = pre_test_log_count + 1
	Log.warning(self, test_log_string)
	updated_log_count = Log.total_log_calls
	assert_eq(updated_log_count, expected_post_test_log_count)
	
	pre_test_log_count = Log.total_log_calls
	expected_post_test_log_count = pre_test_log_count + 1
	Log.error(self, test_log_string)
	updated_log_count = Log.total_log_calls
	assert_eq(updated_log_count, expected_post_test_log_count)
	
	# re-enable flags
	Log.allow_log_output = true
	Log.allow_log_registration = true


# test if log counter is incrementing on successful log call
func test_log_counts() -> void:
	# cannot disable log output for testing log output count, log spam required
	var test_log_string := "test log please ignore"
	
	var pre_test_log_count := Log.total_log_output
	var expected_post_test_log_count = pre_test_log_count + 1
	Log.info(self, test_log_string)
	var updated_log_count := Log.total_log_output
	assert_eq(updated_log_count, expected_post_test_log_count)
	
	pre_test_log_count = Log.total_log_output
	expected_post_test_log_count = pre_test_log_count + 1
	Log.warning(self, test_log_string)
	updated_log_count = Log.total_log_output
	assert_eq(updated_log_count, expected_post_test_log_count)
	
	pre_test_log_count = Log.total_log_output
	expected_post_test_log_count = pre_test_log_count + 1
	Log.error(self, test_log_string)
	updated_log_count = Log.total_log_output
	assert_eq(updated_log_count, expected_post_test_log_count)
