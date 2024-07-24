extends GutTest

# creates a series of test directories and files (removing afterwards)
# runs DataUtility method tests

##############################################################################

# todo list

##############################################################################

# test-scoped variants here

const TEST_DIRECTORY_ROOT := "res://tests/unit/utilities/util_data_test_directory/"
const TEST_DIRECTORY_1 := "test_directory_number_one"
const TEST_DIRECTORY_2 := "test_directory_number_two"
const TEST_DIRECTORY_3 := "test_directory_number_three"


##############################################################################

# test meta methods


func before_all():
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY_ROOT)
	DirAccess.make_dir_absolute(TEST_DIRECTORY_ROOT+TEST_DIRECTORY_1)
	DirAccess.make_dir_absolute(TEST_DIRECTORY_ROOT+TEST_DIRECTORY_2)
	DirAccess.make_dir_absolute(TEST_DIRECTORY_ROOT+TEST_DIRECTORY_3)


func after_all():
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT+TEST_DIRECTORY_1)
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT+TEST_DIRECTORY_2)
	DirAccess.remove_absolute(TEST_DIRECTORY_ROOT+TEST_DIRECTORY_3)
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
	for item in actual_test_directory_names:
		assert_has(expected_test_directory_names, item)


func test_get_dir_paths_recursive() -> void:
	var expected_test_directory_paths = [
		TEST_DIRECTORY_ROOT+TEST_DIRECTORY_1,
		TEST_DIRECTORY_ROOT+TEST_DIRECTORY_2,
		TEST_DIRECTORY_ROOT+TEST_DIRECTORY_3
	]
	var actual_test_directory_paths := DataUtility.get_dir_paths(TEST_DIRECTORY_ROOT)
	for item in actual_test_directory_paths:
		assert_has(expected_test_directory_paths, item)


#//TODO
func test_get_file_paths() -> void:
	#DataUtility.get_file_paths()
	pass_test("TODO test_get_file_paths")


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

