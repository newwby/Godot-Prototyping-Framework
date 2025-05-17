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
const TEST_DATA_FILENAME := "data_register_stub_test_data.json"
const TEST_SCHEMA_FILENAME := "data_register_stub_test_schema.json"
const TEST_USER_SCHEMA = {
	"1.0": {
		"test_data_name": "",
		"test_data_value_1": 0.0,
		"test_data_value_2": [],
		}
	}
const TEST_USER_DATA = {
	"schema_id": "demo_item",
	"schema_version": "1.0",
	"id_author": "gpf",
	"id_package": "testpkg",
	"id_name": "demo_file",
	"type": "testing",
	"tags": [],
	"data": {
		"test_data_name": "",
		"test_data_value_1": 0.0,
		"test_data_value_2": [],
		"name": "Not an item but added for testing",
		"cost": 0.0,
	}
}

var test_data_path := "{0}/{1}".format([Data.get_user_data_path(), "nested_dir"])
var test_schema_path := "{0}/{1}".format([Data.get_user_data_path(), "_schema"])

# test data utilised by tests that need to add dummy data
# must match structure of 'demo_item_potion.json' in res://<data_path>
# (see REQUIREMENTS)
var expected_local_test_data = {
	"schema_id": "demo_item",
	"schema_version": "1.0",
	"id_author": "gpf",
	"id_package": "testpkg",
	"id_name": "demo_potion",
	"type": "undefined",
	"tags": [],
	"data": {
		"name": "Red Potion",
		"cost": 10.0,
	}
}


##############################################################################

# test setup


func before_all():
	_write_test_user_data()
	# reload Data singleton
	Data.clear_all_data()
	Data.load_all_data()


func after_all():
	_remove_test_user_data()
	_remove_test_user_schema()
	# now missing data is still in memory at this point
	#Data.clear_all_data()
	#Data.load_all_data()


##############################################################################

# tests proper


func test_apply_json_data():
	var expected_prop_value_1 := 7.0
	var expected_prop_value_2 := "Hello World!"
	var stub_json_data = {
	"schema_id": "fake_schema",
	"schema_version": "1.0",
	"id_author": "null",
	"id_package": "null",
	"id_name": "mock_json_replacer",
	"type": "undefined",
	"tags": [],
	"data": {
		"test_property_1": expected_prop_value_1,
		"test_property_2": expected_prop_value_2,
		"test_property_unnamed": 10.0
	}
	}
	# test_property_unnamed exists to ensure properties missing on the target
	#	object can exist within the jsonData without issue
	var test_object := MockJsonReceiver.new()
	Data.apply_json(test_object, stub_json_data)
	assert_eq(test_object.test_property_1, expected_prop_value_1)
	assert_eq(test_object.test_property_2, expected_prop_value_2)


# test checks that the Data singleton can be cleared
func test_clear_data():
	Data.clear_all_data()
	assert_eq(Data.data_collection.is_empty(), true)
	assert_eq(Data.data_id_register.is_empty(), true)
	assert_eq(Data.data_author_register.is_empty(), true)
	assert_eq(Data.data_package_register.is_empty(), true)
	assert_eq(Data.data_schema_register.is_empty(), true)
	assert_eq(Data.data_tag_register.is_empty(), true)
	assert_eq(Data.data_type_register.is_empty(), true)
	# must reload for later tests
	Data.load_all_data()


# checks new data can be added, reloaded, and fetched by Data singleton
# establishes that data can be loaded from user:// as well
# this test is potentially a duplicate of before_all/after_all behaviour
#	but provides an error endpoint for if that behaviour breaks
func test_load_data_forcibly():
	var dir_path := "{0}/{1}".format([
		Data.get_user_data_path(),
		"_test_load_data_forcibly"
	])
	var file_name := "testfile.json"
	var full_path := "{0}/{1}".format([dir_path, file_name])
	var data = expected_local_test_data.duplicate()
	data["path"] = full_path
	data["id_author"] = "test_load_data_forcibly"
	
	var absolute_dir_path := ProjectSettings.globalize_path(dir_path)
	if DataUtility.validate_directory(absolute_dir_path) == false:
		DirAccess.make_dir_recursive_absolute(absolute_dir_path)
	var absolute_file_path := ProjectSettings.globalize_path(full_path)
	
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	
	if FileAccess.file_exists(absolute_file_path) == false:
		fail_test("test_load_data_forcibly file creation unsucessful!")
		return
	
	Data.clear_all_data()
	Data.load_all_data()
	var fetched_data = Data.fetch_by_id("{0}.{1}.{2}".format([
		data["id_author"],
		data["id_package"],
		data["id_name"]
	]))
	
	# test data
	assert_eq(data, fetched_data)
	
	# clear data from the test
	DirAccess.remove_absolute(absolute_file_path)
	DirAccess.remove_absolute(absolute_dir_path)


# requires before_all behaviour
# tests that data can be loaded from nested directories
# establishes that data can be loaded from user:// as well
func test_load_data_nested():
	# setup and teardown for this test is done in before_all/after_all
	var fetched_user_data := Data.fetch_by_id("{0}.{1}.{2}".format([
		TEST_USER_DATA["id_author"],
		TEST_USER_DATA["id_package"],
		TEST_USER_DATA["id_name"],
	]))
	# path is applied during data loading, needs to be accommodated in tests
	var path_adj_data = TEST_USER_DATA.duplicate()
	path_adj_data["path"] = "{0}/{1}".format([test_data_path, TEST_DATA_FILENAME])
	assert_eq(fetched_user_data, path_adj_data)
	# why do these print in diff orders
	print(path_adj_data)
	print("\n\n", fetched_user_data)


# applies an incorrectly formatted id to the register
# expect warning on test
func test_fetch_malformed_id():
	var malformed_id := "author.package.id.fourththing"
	Data.data_id_register[malformed_id] = expected_local_test_data
	Log.info(self, "expect imminent Data warning for malformed id test")
	var result := Data.fetch_by_id(malformed_id)
	assert_eq(result, {})


# checks if fetch_by_id returns the correct value on missing data
func test_fetch_missing_id():
	var test_id := "test_missing_id.test_data_register.test_id"
	assert_eq(Data.data_id_register.has(test_id), false)
	Log.info(self, "expect imminent Data warning for missing id test")
	assert_eq(Data.fetch_by_id(test_id), {})


# check if fetch_by_id functions as expected, returning correct value
# test tears down the test value at conclusion
func test_fetch_existing_id():
	var test_id := "test_existing_id.test_data_register.test_id"
	Data.data_id_register[test_id] = expected_local_test_data
	assert_eq(Data.fetch_by_id(test_id), expected_local_test_data)
	# remove testing data, check it is gone
	Data.data_id_register.erase(test_id)
	Log.info(self, "expect imminent Data warning for existing id test teardown")
	assert_does_not_have(Data.fetch_by_id(test_id), expected_local_test_data)
	assert_eq(Data.fetch_by_id(test_id), {})


# checks if fetch_by_author returns the correct value on missing data
func test_fetch_missing_author():
	var test_author := "fake_missing_author_for_test_fetch_missing_author"
	assert_eq(Data.data_author_register.has(test_author), false)
	Log.info(self, "expect imminent Data warning for missing author test")
	assert_eq(Data.fetch_by_author(test_author), [])


# check if data exists in author register and fetch_by_author returns expected result
# test tears down the test value at conclusion
func test_fetch_existing_author():
	var test_author := "faked_present_author_for_test_fetch_existing_author"
	var test_data = [
		expected_local_test_data,
		expected_local_test_data,
		expected_local_test_data
	]
	Data.data_author_register[test_author] = test_data
	assert_has(Data.fetch_by_author(test_author), expected_local_test_data)
	assert_eq(Data.fetch_by_author(test_author), test_data)
	assert_eq(Data.fetch_by_author(test_author).size(), 3)
	# remove testing data, check it is gone
	Data.data_author_register.erase(test_author)
	Log.info(self, "expect imminent Data warning for existing author test teardown")
	assert_does_not_have(Data.fetch_by_author(test_author), test_data)
	assert_eq(Data.fetch_by_author(test_author), [])


# checks if fetch_by_package returns the correct value on missing data
func test_fetch_missing_package():
	var test_package := "fake_missing_package_for_test_fetch_missing_package"
	assert_eq(Data.data_package_register.has(test_package), false)
	Log.info(self, "expect imminent Data warning for missing package test")
	assert_eq(Data.fetch_by_package(test_package), [])


# check if data exists in package register and fetch_by_package returns expected result
# test tears down the test value at conclusion
func test_fetch_existing_package():
	var test_package := "faked_present_package_for_test_fetch_existing_package"
	var test_data = [
		expected_local_test_data,
		expected_local_test_data,
	]
	Data.data_package_register[test_package] = test_data
	assert_has(Data.fetch_by_package(test_package), expected_local_test_data)
	assert_eq(Data.fetch_by_package(test_package), test_data)
	assert_eq(Data.fetch_by_package(test_package).size(), 2)
	# remove testing data, check it is gone
	Data.data_package_register.erase(test_package)
	Log.info(self, "expect imminent Data warning for existing package test teardown")
	assert_does_not_have(Data.fetch_by_package(test_package), test_data)
	assert_eq(Data.fetch_by_package(test_package), [])


# checks if fetch_by_schema returns the correct value on missing data
func test_fetch_missing_schema():
	var test_schema := "fake_missing_schema_for_test_fetch_by_schema"
	assert_eq(Data.data_package_register.has(test_schema), false)
	Log.info(self, "expect imminent Data warning for missing schema test")
	assert_eq(Data.fetch_by_schema(test_schema), [])


# check if data exists in package register and fetch_by_schema returns expected result
# test tears down the test value at conclusion
func test_fetch_existing_schema():
	var test_schema := "faked_present_schema_for_test_fetch_existing_schema"
	var test_data = [
		expected_local_test_data,
		expected_local_test_data,
		expected_local_test_data,
	]
	Data.data_schema_register[test_schema] = test_data
	assert_has(Data.fetch_by_schema(test_schema), expected_local_test_data)
	assert_eq(Data.fetch_by_schema(test_schema), test_data)
	assert_eq(Data.fetch_by_schema(test_schema).size(), 3)
	# remove testing data, check it is gone
	Data.data_schema_register.erase(test_schema)
	Log.info(self, "expect imminent Data warning for existing package test teardown")
	assert_does_not_have(Data.fetch_by_schema(test_schema), test_data)
	assert_eq(Data.fetch_by_schema(test_schema), [])


# checks if fetch_by_tag returns the correct value on missing data
func test_fetch_missing_tag():
	var test_tag := "fake_missing_tag_for_test_fetch_missing_tag"
	assert_eq(Data.data_tag_register.has(test_tag), false)
	Log.info(self, "expect imminent Data warning for missing tag test")
	assert_eq(Data.fetch_by_tag(test_tag), [])


# check if data exists in tag register and fetch_by_tag returns expected result
# test tears down the test value at conclusion
func test_fetch_existing_tag():
	var test_tag := "faked_present_tag_for_test_fetch_existing_tag"
	var test_data = [
		expected_local_test_data,
		expected_local_test_data
	]
	Data.data_tag_register[test_tag] = test_data
	assert_has(Data.fetch_by_tag(test_tag), expected_local_test_data)
	assert_eq(Data.fetch_by_tag(test_tag), test_data)
	assert_eq(Data.fetch_by_tag(test_tag).size(), 2)
	# remove testing data, check it is gone
	Data.data_tag_register.erase(test_tag)
	Log.info(self, "expect imminent Data warning for existing tag test teardown")
	assert_does_not_have(Data.fetch_by_tag(test_tag), test_data)
	assert_eq(Data.fetch_by_tag(test_tag), [])


# checks if fetch_by_type returns the correct value on missing data
func test_fetch_missing_type():
	var test_type := "fake_missing_type_for_test_fetch_missing_type"
	assert_eq(Data.data_type_register.has(test_type), false)
	Log.info(self, "expect imminent Data warning for missing type test")
	assert_eq(Data.fetch_by_type(test_type), [])


# check if data exists in type register and fetch_by_type returns expected result
# test tears down the test value at conclusion
func test_fetch_existing_type():
	var test_type := "faked_present_type_for_test_fetch_existing_type"
	var test_data = [
		expected_local_test_data,
		expected_local_test_data,
		expected_local_test_data
	]
	Data.data_type_register[test_type] = test_data
	assert_has(Data.fetch_by_type(test_type), expected_local_test_data)
	assert_eq(Data.fetch_by_type(test_type), test_data)
	assert_eq(Data.fetch_by_type(test_type).size(), 3)
	# remove testing data, check it is gone
	Data.data_type_register.erase(test_type)
	Log.info(self, "expect imminent Data warning for existing type test teardown")
	assert_does_not_have(Data.fetch_by_type(test_type), test_data)
	assert_eq(Data.fetch_by_type(test_type), [])


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
func test_local_data_fetched() -> void:
	var id_author = expected_local_test_data["id_author"]
	var id_package = expected_local_test_data["id_package"]
	var id_name = expected_local_test_data["id_name"]
	var fetched_data = Data.fetch_by_id("{0}.{1}.{2}".\
			format([id_author, id_package, id_name]))
	# prune path which wasn't included in testing data but is added in data verification step
	if fetched_data.has("path"):
		fetched_data.erase("path")
	assert_eq(fetched_data, expected_local_test_data)
	if fetched_data != expected_local_test_data:
		Log.warning(self, "test_local_data_fetched - fetched data does not match expected test data.\n{0}\nvs\n{1}".\
				format([fetched_data, expected_local_test_data]))


# verifies specific files (included with the framework dev build) exist and
#	can be read
func test_local_schema_exists() -> void:
	var test_local_schema_path := "{0}/_schema/demo_weapon.json".format([Data.get_local_data_path()])
	# must match structure of 'demo_item.json' in res://<data_path>/_schema
	# (see REQUIREMENTS)
	var expected_test_schema = {
	"1.0": {
		"name": "",
		"cost": 0.0,
		"damage": 3.0,
		},
	"1.1": {
		"name": "",
		"cost": 0.0,
		"damage": 3.0,
		"range": 2.0,
		}
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


##############################################################################

# private test setup methods, not tests


func _remove_test_user_schema() -> void:
	pass
	# schema teardown
	#var full_schema_path := "{0}/{1}".format([
		#test_schema_path,
		#TEST_SCHEMA_FILENAME
	#])
	#var absolute_schema_path := ProjectSettings.globalize_path(full_schema_path)
	#var absolute_schema_dir_path := ProjectSettings.globalize_path(test_schema_path)
	#DirAccess.remove_absolute(absolute_schema_path)
	#DirAccess.remove_absolute(absolute_schema_dir_path)


func _remove_test_user_data() -> void:
	# data file teardown
	var full_file_path := "{0}/{1}".format([
		test_data_path,
		TEST_DATA_FILENAME
	])
	var absolute_file_path := ProjectSettings.globalize_path(full_file_path)
	var absolute_data_dir_path := ProjectSettings.globalize_path(test_data_path)
	DirAccess.remove_absolute(absolute_file_path)
	DirAccess.remove_absolute(absolute_data_dir_path)


func _write_test_user_data() -> void:
	# data file structuring
	var full_file_path := "{0}/{1}".format([
		test_data_path,
		TEST_DATA_FILENAME
	])
	var absolute_file_path := ProjectSettings.globalize_path(full_file_path)
	var absolute_data_dir_path := ProjectSettings.globalize_path(test_data_path)
	if DataUtility.validate_directory(absolute_data_dir_path) == false:
		DirAccess.make_dir_recursive_absolute(absolute_data_dir_path)
	
	var file = FileAccess.open(absolute_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(TEST_USER_DATA))
	file.close()
