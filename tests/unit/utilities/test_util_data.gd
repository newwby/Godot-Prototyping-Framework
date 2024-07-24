extends GutTest

# creates a series of test directories and files (removing afterwards)
# runs DataUtility method tests

##############################################################################

# todo list

##############################################################################

# test-scoped variants here

# paths to directories and files created as part of the testing process
const TEST_DIRECTORY_ROOT := "res://tests/unit/utilities/util_data_test_directory"
const TEST_DIRECTORY_1 := "test_directory_number_one"
const TEST_DIRECTORY_2 := "test_directory_number_two"
const TEST_DIRECTORY_3 := "test_directory_number_three"
const TEST_FILE_1A := "test_file_1a.tres"
const TEST_FILE_1B := "test_file_1b.tres"
const TEST_FILE_2A := "test_file_2a.tres"
const TEST_FILE_3A := "test_file_3a.tres"
const TEST_FILE_3B := "test_file_3b.tres"
const TEST_FILE_3C := "test_file_3c.tres"


var all_test_file_names := [
		TEST_FILE_1A,
		TEST_FILE_1B,
		TEST_FILE_2A,
		TEST_FILE_3A,
		TEST_FILE_3B,
		TEST_FILE_3C,
	]

var all_test_file_paths := [
	TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_1+"/"+TEST_FILE_1A,
	TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_1+"/"+TEST_FILE_1B,
	TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_2+"/"+TEST_FILE_2A,
	TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_3+"/"+TEST_FILE_3A,
	TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_3+"/"+TEST_FILE_3B,
	TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_3+"/"+TEST_FILE_3C
	]

##############################################################################

# test meta methods


# create the test files
func before_all():
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY_ROOT)
	DirAccess.make_dir_absolute(TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_1)
	DirAccess.make_dir_absolute(TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_2)
	DirAccess.make_dir_absolute(TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_3)
	for test_file_path in all_test_file_paths:
		var new_test_file = Resource.new()
		assert_eq(ResourceSaver.save(new_test_file, test_file_path), OK)


# clean up the test files
func after_all():
	for test_file_path in all_test_file_paths:
		assert_eq(DirAccess.remove_absolute(test_file_path), OK)
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_1)
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_2)
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_3)
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT)


##############################################################################

# tests


func test_clean_file_name() -> void:
	var testable_incorrect_file_name = ">.> THIS FILE NAME IS EASILY 50%+ WRONG: *full of invalid characters!*"
	var cleaned_file_name := DataUtility.clean_file_name(testable_incorrect_file_name)
	if cleaned_file_name.is_valid_filename():
		pass_test("test_clean_file_name passed w/valid file name {0}!".format([cleaned_file_name]))
	else:
		fail_test("test_clean_file_name failed w/invalid file name {0}!".format([cleaned_file_name]))


func test_get_dir_names_recursive() -> void:
	var expected_test_directory_names = [
		TEST_DIRECTORY_1,
		TEST_DIRECTORY_2,
		TEST_DIRECTORY_3
	]
	var actual_test_directory_names := DataUtility.get_dir_names_recursive(TEST_DIRECTORY_ROOT)
	assert_eq(actual_test_directory_names.is_empty(), false)
	for dir_name in actual_test_directory_names:
		assert_has(expected_test_directory_names, dir_name)


func test_get_dir_paths_recursive() -> void:
	var expected_test_directory_paths = [
		TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_1,
		TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_2,
		TEST_DIRECTORY_ROOT+"/"+TEST_DIRECTORY_3
	]
	var actual_test_directory_paths := DataUtility.get_dir_paths(TEST_DIRECTORY_ROOT)
	assert_eq(actual_test_directory_paths.is_empty(), false)
	for dir_path in actual_test_directory_paths:
		assert_has(expected_test_directory_paths, dir_path)


func test_get_file_names() -> void:
	var actual_test_file_names := DataUtility.get_file_names(TEST_DIRECTORY_ROOT)
	assert_eq(actual_test_file_names.is_empty(), false)
	for file_name in actual_test_file_names:
		assert_has(all_test_file_names, file_name)


func test_get_file_paths() -> void:
	var actual_test_file_paths := DataUtility.get_file_paths(TEST_DIRECTORY_ROOT)
	assert_eq(actual_test_file_paths.is_empty(), false)
	for file_path in actual_test_file_paths:
		assert_has(all_test_file_paths, file_path)


#//TODO
func test_save_resource() -> void:
	#DataUtility.save_resource()
	pass_test("TODO test_save_resource")


#//TODO
func test_validate_directory() -> void:
	#DataUtility.validate_directory()
	pass_test("TODO test_validate_directory")


#//TODO
func test_validate_file() -> void:
	#DataUtility.validate_file()
	pass_test("TODO test_validate_file")

