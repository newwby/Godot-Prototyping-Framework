#class_name class
extends GutTest

# creates a series of directories
# runs data utility tests

const TEST_DIRECTORY_ROOT := "res://tests/unit/utilities/util_data_test_directory/"
const TEST_DIRECTORY_1 := "test_directory_number_one"
const TEST_DIRECTORY_2 := "test_directory_number_two"
const TEST_DIRECTORY_3 := "test_directory_number_three"


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

