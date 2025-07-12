extends GutTest

# tests for the save_resource method

##############################################################################

##############################################################################

# test-scoped variants here

const DIRECTORY_PATH = "user://test_save_resource_temp_directory"
const FILE_NAME = "save_resource_test_file"
const FILE_EXT = ".tres"

var file_test_path_default = "{0}/{1}{2}".format([DIRECTORY_PATH, FILE_NAME, FILE_EXT])
var file_test_path_backup = "{0}/{1}{2}".format([DIRECTORY_PATH, FILE_NAME+DataUtility.BACKUP_SUFFIX, FILE_EXT])

##############################################################################

# test meta methods


# alias for prerun_setup
func before_all():
	# setup test directory
	DirAccess.make_dir_absolute(DIRECTORY_PATH)


# alias for setup
#func before_each():
#	pass


# alias for postrun_teardown
func after_all():
	# remove testing resources
	DirAccess.remove_absolute(file_test_path_backup)
	DirAccess.remove_absolute(file_test_path_default)
	DirAccess.remove_absolute(DIRECTORY_PATH)


# alias for teardown
#func after_each():
#	pass


##############################################################################

# tests


# values are not verified due to bug with file writing/loading in the same
#	method (kept getting the previous file no matter the wait time)
func test_save_resource() -> void:
	# no file or backup should exist before test
	assert_eq(FileAccess.file_exists(file_test_path_default), false)
	assert_eq(FileAccess.file_exists(file_test_path_backup), false)
	# save resource id 42
	_save_behaviour_1()
	# on first save the file should exist but not the backup
	assert_eq(FileAccess.file_exists(file_test_path_default), true)
	assert_eq(FileAccess.file_exists(file_test_path_backup), false)
	
	# verify the active file (expected id 42)
	_verify_value(file_test_path_default, 42)
	
	# save resource id 117, expected behaviour is resource id 42 is now the backup
	_save_behaviour_2()
	# on second save both backup and file should exist
	assert_eq(FileAccess.file_exists(file_test_path_default), true)
	assert_eq(FileAccess.file_exists(file_test_path_backup), true)
	
	# verify the active file (expected id 117)
	_verify_value(file_test_path_default, 117)
	# verify the backup file (expected id 42)
	_verify_value(file_test_path_backup, 42)


##############################################################################


# save behaviour is separated into separate methods because the files
#	will not update on disk whilst within the same method (known bug)
func _save_behaviour_1() -> void:
	var test_file_1 = DataUtilityTestResource.new()
	test_file_1.id = 42
	DataUtility.save_resource(test_file_1, file_test_path_default, true)


# save behaviour is separated into separate methods because the files
#	will not update on disk whilst within the same method (known bug)
func _save_behaviour_2() -> void:
	var test_file_2 = DataUtilityTestResource.new()
	test_file_2.id = 117
	DataUtility.save_resource(test_file_2, file_test_path_default, true)


func _verify_value(arg_path: String, arg_id_value: int) -> void:
	var test_res_loaded = ResourceLoader.load(arg_path)
	assert_eq(test_res_loaded is DataUtilityTestResource, true)
	if "id" in test_res_loaded:
		assert_eq(test_res_loaded.id, arg_id_value)
	else:
		fail_test("id property not found on test_res_loaded")
