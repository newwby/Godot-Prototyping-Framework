extends GutTest

# checks - with stub data - if globalData can load json files accurately
# this test checks that local data and user data can be found in GlobalData
#	after the singleton is told to reset and reload (initialisation methods)
# as a consequence of these tests it also tests writing to userData
# also tests that GlobalData paths are valid by plugin project setting

#//REQUIREMENTS
# file 'demo_item_potion.json' exists in res://<data_path>, matching expected structure
# file 'demo_item.json' exists in res://<data_path>/_schema, matching expected structure
# (where <data_path> equals string returned from 'GPFPlugin.get_data_path_setting()')

##############################################################################

#//TODO
# add mock for user data writing, so can decouple testing of writing to user://

##############################################################################

# test-scoped variants here

# custom testing schema and data written to user://<data_path>
const TEST_DATA_FILENAME := "data_register_stub_test_data"
const TEST_SCHEMA_FILENAME := "data_register_stub_test_schema"
const TEST_USER_SCHEMA = {
	"1.0": {
		"test_data_name": "",
		"test_data_value_1": 0,
		"test_data_value_2": [],
		}
	}
const TEST_USER_DATA = {
	"schema_id": "demo_item",
	"version_id": "consumable 1.0",
	"author": "prototype_framework",
	"type": "undefined",
	"tags": [],
	"data": {
		"name": "Red Potion",
		"cost": 10,
	}
}

##############################################################################

# tests


# alias for prerun_setup
func before_all():
	pass


# alias for postrun_teardown
func after_all():
	pass


# verifies specific files (included with the framework dev build) exist and
#	can be read
func test_local_data_exists() -> void:
	var test_local_data_path := "{0}/demo_item_potion.json".format([Data.get_local_data_path()])
	# must match structure of 'demo_item_potion.json' in res://<data_path>
	# (see REQUIREMENTS)
	var expected_test_data = {
		"schema_id": "demo_item",
		"version_id": "consumable 1.0",
		"author": "prototype_framework",
		"type": "undefined",
		"tags": [],
		"data": {
			"name": "Red Potion",
			"cost": 10.0,
		}
	}
	var file = FileAccess.open(test_local_data_path, FileAccess.READ)
	var json_file = JSON.new()
	if json_file.parse(file.get_as_text()) == OK:
		var content = json_file.data
		assert_eq(content, expected_test_data)
	else:
		fail_test("cannot read file")


# verifies specific files (included with the framework dev build) exist and
#	can be read
func test_local_schema_exists() -> void:
	var test_local_schema_path := "{0}/_schema/demo_item.json".format([Data.get_local_data_path()])
	# must match structure of 'demo_item.json' in res://<data_path>/_schema
	# (see REQUIREMENTS)
	var expected_test_schema = {
		"consumable 1.0": {
			"name": "",
			"cost": 0.0,
		},
		"weapon 1.0": {
			"name": "",
			"cost": 0.0,
			"damage": 3.0,
		},
	}
	var file = FileAccess.open(test_local_schema_path, FileAccess.READ)
	var json_file = JSON.new()
	if file == null:
		fail_test("cannot open file")
		return
	if json_file.parse(file.get_as_text()) == OK:
		var content = json_file.data
		assert_eq(content, expected_test_schema)
	else:
		fail_test("cannot read file")


## test if log call is incrementing even without output/registration
#func test_log_calls() -> void:
	## no need to record or log spam when testing calls
	#Log.allow_log_output = false
	#Log.allow_log_registration = false
	#var test_log_string := "testing log counting"
	#
	#var pre_test_log_count := Log.total_log_calls
	#var expected_post_test_log_count = pre_test_log_count + 1
	#Log.info(self, test_log_string)
	#var updated_log_count := Log.total_log_calls
	#assert_eq(updated_log_count, expected_post_test_log_count)
	#
	#pre_test_log_count = Log.total_log_calls
	#expected_post_test_log_count = pre_test_log_count + 1
	#Log.warning(self, test_log_string)
	#updated_log_count = Log.total_log_calls
	#assert_eq(updated_log_count, expected_post_test_log_count)
	#
	#pre_test_log_count = Log.total_log_calls
	#expected_post_test_log_count = pre_test_log_count + 1
	#Log.error(self, test_log_string)
	#updated_log_count = Log.total_log_calls
	#assert_eq(updated_log_count, expected_post_test_log_count)
	#
	## re-enable flags
	#Log.allow_log_output = true
	#Log.allow_log_registration = true
