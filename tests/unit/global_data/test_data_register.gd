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
# make sure to reload globalData on writing user data

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
	"schema_version": "consumable 1.0",
	"id_author": "prototype_framework",
	"id_package": "demo_data",
	"id_name": "demo_potion",
	"type": "undefined",
	"tags": [],
	"data": {
		"name": "Red Potion",
		"cost": 10,
	}
}
# must match structure of 'demo_item_potion.json' in res://<data_path>
# (see REQUIREMENTS)
var expected_local_test_data = {
	"schema_id": "demo_item",
	"schema_version": "consumable 1.0",
	"id_author": "prototype_framework",
	"id_package": "demo_data",
	"id_name": "demo_potion",
	"type": "undefined",
	"tags": [],
	"data": {
		"name": "Red Potion",
		"cost": 10.0,
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
	var file = FileAccess.open(test_local_data_path, FileAccess.READ)
	var json_file = JSON.new()
	if json_file.parse(file.get_as_text()) == OK:
		var content = json_file.data
		assert_eq(content, expected_local_test_data)
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


# verifies specific files (included with the framework dev build) exist and
#	can be read
func test_local_data_fetched() -> void:
	var id_author = expected_local_test_data["id_author"]
	var id_package = expected_local_test_data["id_package"]
	var name = expected_local_test_data["id_name"]
	var fetched_data = Data.fetch_by_id("{0}.{1}.{2}".\
			format([id_author, id_package, name]))
	assert_eq(fetched_data, expected_local_test_data)
