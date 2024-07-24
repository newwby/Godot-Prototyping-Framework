extends Node

class_name DataUtility

##############################################################################

# DataUtility is collection of static data management methods

##############################################################################

#//TODO
#// add (reintroduce) save/load method pair for json-dict
#// add a save/load method pair for config ini file
#// add a save/load method pair for store_var/any node

#// add file backups optional arg (push_backup on save, try_backup on load);
#		file backups are '-backup1.tres', '-backup2.tres', etc.
#		backups are tried sequentially if error on loading resource
#		add customisable variable for how many backups to keep

#// add error logging for failed move_to_trash on save_resource
#// update error logging for save resource temp_file writing

#// add optional arg for making write_directory recursive (currently default)

#// add a minor logging method for get_file_paths (globalDebug update)

#// update save resource method or resourceLoad to handle .backup not .tres
#// add recursive param to load_resources_in_directory

#// update load_resource to try and load resource on fail state

##############################################################################


# constants to avoid user error typing
const LOCAL_PATH := "res://"
const USER_PATH := "user://"

# the suffix (before file extension) for backups
const BACKUP_SUFFIX := "_backup"
const TEMP_SUFFIX := "_temp"

# file extension for text resource files
const EXT_RESOURCE := ".tres"

##############################################################################

# public methods


#static func clean_file_name(arg_file_name: String) -> String:
	#return arg_file_name.replace("/[/\\?%*:|\"<>]/g", '-')


# this method provides additional functionality compared to validate_filename
# strips invalid characters from a file name, optionally replacing with a passed
#	character; can also replace spaces with the same character if desired
# converts given file name to lower case
# on return warns if still invalid
# most importantly provdies options for how to handle spaces/case
# cleans file names for Windows OS
#//TODO add additional handling for Mac/Linux/Android/iOS
static func clean_file_name(
		arg_file_name: String,
		arg_replace_char: String = "",
		arg_replace_spaces: bool = true,
		arg_to_lowercase: bool = true) -> String:
	var new_string := arg_file_name
	var banned_chars := [":", "/", "\\", "?", "*", "\"", "|", "%", "<", ">"]
	if new_string.is_valid_filename() == false:
		for invalid_char in banned_chars:
			new_string = new_string.replace(invalid_char, arg_replace_char)
	if arg_replace_spaces:
		new_string = new_string.replace(" ", arg_replace_char)
	if arg_to_lowercase:
		new_string = new_string.to_lower()
	if new_string.is_valid_filename() == false:
		GlobalLog.warning(null, "invalid filename output {0} on DataUtility.clean_file_name".format([new_string]))
	return new_string


# returns names of all directories within a path (recursively)
static func get_dir_names_recursive(
		arg_directory_path: String
		) -> PackedStringArray:
	# validate path
	var directory_name := ""
	var return_directory_names: PackedStringArray = []
	# find the directory, loop through the directory
	var dir_access = DirAccess.open(arg_directory_path)
	if DirAccess.get_open_error() == OK:
		# skip if directory couldn't be opened
		# skip navigational and hidden
		if dir_access.list_dir_begin()  != OK:
			return return_directory_names
		
		directory_name = dir_access.get_next()
		while directory_name != "":
			# check isn't a directory (i.e. is a file)
			if dir_access.current_is_dir():
				return_directory_names.append(directory_name)
			# end of loop
			directory_name = dir_access.get_next()
		
		dir_access.list_dir_end()
	return return_directory_names


# method returns paths for every directory inside a directory path
# can search recursively (default behaviour), returning all nested directories
#//TODO rewrite with DirAccess methods
#//TODO get_dir_paths/get_dir_names could be a single method
static func get_dir_paths(
		arg_directory_path: String,
		arg_get_recursively: bool = false) -> Array:
	var directories_inside = []
	var invalid_directory_errorstring := "DataHandler {0} is invalid for {1}".format([
			str(arg_directory_path), "get_dir_paths"])
	
	var dir_access := DirAccess.open(arg_directory_path)
	# err handling
	if DirAccess.get_open_error() != OK:
		GlobalLog.error(null, invalid_directory_errorstring)
		return directories_inside
	if dir_access.list_dir_begin()  != OK:# TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		GlobalLog.error(null, invalid_directory_errorstring)
		return directories_inside
	
	# otherwise assume OK
	# searching given directory subdirectories
	var dir_name := dir_access.get_next()
	var path_to_current_dir = ""
	while dir_name != "":
		if dir_access.current_is_dir():
			path_to_current_dir = dir_access.get_current_dir()+"/"+dir_name
			directories_inside.append(path_to_current_dir)
		dir_name = dir_access.get_next()
	# close before reading subdirectories
	dir_access.list_dir_end()
	
	# search found directories to see if they have directories inside
	if arg_get_recursively and not directories_inside.is_empty():
		for subdirectory_path in directories_inside:
			directories_inside.append_array(\
					get_dir_paths(subdirectory_path))
	
	return directories_inside



# clone of get_file_paths that only returns the names of any files found
# if arg_is_recursive is set false will only search the exact directory given
static func get_file_names(
		arg_directory_path: String,
		arg_is_recursive: bool = true) -> PackedStringArray:
	var output := PackedStringArray([])
	var subdirectories = DirAccess.get_directories_at(arg_directory_path)
	if subdirectories.is_empty() == false and arg_is_recursive:
		for subdirectory_path in subdirectories:
			output.append_array(get_file_names(arg_directory_path+"/"+subdirectory_path, arg_is_recursive))
	var file_names = DirAccess.get_files_at(arg_directory_path)
	output.append_array(file_names)
	return output


# Fetches the file path for every file in a directory (recursively by default)
# if arg_is_recursive is set false will only search the exact directory given
static func get_file_paths(
		arg_directory_path: String,
		arg_is_recursive: bool = true) -> PackedStringArray:
	var output := PackedStringArray([])
	var subdirectories = DirAccess.get_directories_at(arg_directory_path)
	if subdirectories.is_empty() == false and arg_is_recursive:
		for subdirectory_path in subdirectories:
			output.append_array(get_file_paths(arg_directory_path+"/"+subdirectory_path, arg_is_recursive))
	var file_names = DirAccess.get_files_at(arg_directory_path)
	var file_path_output = []
	for file_name in file_names:
		file_path_output.append(arg_directory_path+"/"+file_name)
	output.append_array(file_path_output)
	return output


# method to save any resource or resource-extended custom class to disk.
# call this method with 'if save_resource(*args) == OK' to validate
# if called on a non-existing file or path it will write the entire path
## if arg_backup is specified, any previous file found will be moved to a
##	separate file with the 'BACKUP_SUFFIX' added to its file name
static func save_resource(
		arg_saveable_res: Resource,
		arg_file_path: String,
		arg_backup : bool = false
		) -> Error:
	# check valid path
	if arg_file_path.begins_with("user://") == false:
		GlobalLog.error(null, "DataUtility.save_resource called with non-user file path: {0}".format([arg_file_path]))
		return ERR_INVALID_PARAMETER
	
	# split given file path into constituent parts
	var directory_path = arg_file_path.get_base_dir()
	var file_name_and_extension = arg_file_path.get_file()
	var file_extension = file_name_and_extension.get_extension()
	var file_name = file_name_and_extension.trim_suffix(".{0}".format([file_extension]))
	
	# check given extension is valid, convert if not
	if file_extension != "tres":
		GlobalLog.warning(null, "DataUtility.save_resource called with invalid extension {0}, converting to .tres".format([file_extension]))
		file_extension = "tres"
	
	# create target directory if it doesn't already exist
	if DirAccess.dir_exists_absolute(directory_path) == false:
		DirAccess.make_dir_recursive_absolute(directory_path)
	
	# temporarily write to disk
	var temp_write_path = "{0}/{1}{2}.{3}".format([directory_path, file_name, TEMP_SUFFIX, file_extension])
	var temp_write_outcome = ResourceSaver.save(arg_saveable_res, temp_write_path)
	if temp_write_outcome != OK:
		GlobalLog.error(null, "DataUtility.save_resource could not write temporary file")
	
	# if file exists check for backup behaviour
	if FileAccess.file_exists(arg_file_path):
		# move existing file to backup if specified, or remove it
		if arg_backup:
			# check for existing backup and then send current backup to trash
			var backup_path = "{0}/{1}{2}.{3}".format([directory_path, file_name, BACKUP_SUFFIX, file_extension])
			if FileAccess.file_exists(backup_path):
				var global_backup_path = ProjectSettings.globalize_path(backup_path)
				OS.move_to_trash(global_backup_path)
			# make old file the backup
			DirAccess.rename_absolute(arg_file_path, backup_path)
		# if no backup behaviour, remove the previous file
		else:
			var global_file_path = ProjectSettings.globalize_path(arg_file_path)
			OS.move_to_trash(global_file_path)
		
		## due to bug with DirAccess.rename_absolute (see https://github.com/godotengine/godot/issues/73311)
		##	temporarily just loading and resaving the original file as a backup
		##//TODO revise this, previous issue has been fixed
		#var current_file_at_path = ResourceLoader.load(arg_file_path)
		#if current_file_at_path is Resource:
			#var backup_file_outcome = ResourceSaver.save(current_file_at_path, backup_path)
			#if backup_file_outcome != OK:
				#GlobalLog.warning(null, "DataUtility.save_resource could not save backup")
		#else:
			#GlobalLog.warning(null, "DataUtility.save_resource found non-resource at path, overwriting")
	
	# write behaviour is just moving the temporary file to the now-free file path address
	return DirAccess.rename_absolute(temp_write_path, arg_file_path)



# as the method validate_path, but specifically checking for directories
# useful for one liner conditionals and built-in error logging
# (saves creating a file/directory object manually)
# [method params as follows]
##1, path, is the directory path to validate
##2, arg_assert_path, forces an assert in debug builds and error logging in both
# debug and release builds. Set this param to true when you require a path
# to be valid before you continue with an operation.
static func validate_directory(
		arg_directory_path: String,
		arg_assert_path: bool = false
		) -> bool:
	# call the private validation method as a directory
	return _validate(arg_directory_path, arg_assert_path, false)


# as the method validate_path, but specifically checking for files existing
# useful for one liner conditionals and built-in error logging
# (saves creating a file/directory object manually)
# [method params as follows]
##1, path, is the file path to validate
##2, arg_assert_path, forces an assert in debug builds and error logging in both
# debug and release builds. Set this param to true when you require a path
# to be valid before you continue with an operation.
static func validate_file(
		arg_file_path: String,
		arg_assert_path: bool = false
		) -> bool:
	# call the private validation method as a file
	return _validate(arg_file_path, arg_assert_path, true)



##############################################################################

# private methods


# validation method for public 'save' methods
static func _is_write_operation_directory_valid(arg_directory_path: String) -> int:
	# resources can only be saved to paths within the user data folder.
	# user data path is "user://"
	if arg_directory_path.substr(0, 7) != USER_PATH:
		GlobalLog.error(null,
				"DataHandler {p} is not user_data path".format({"p": arg_directory_path}))
		return ERR_FILE_BAD_PATH
	
	# check if the directory already exists
	if not validate_directory(arg_directory_path):
		# if force writing and directory doesn't exist, create it
		var attempt_write_dir = DirAccess.make_dir_recursive_absolute(arg_directory_path)
		if attempt_write_dir != OK:
			GlobalLog.error(null,
					"DataHandler failed attempt to write directory at {p}".format({
						"p": arg_directory_path
					}))
			return attempt_write_dir
	# if all was successful,
	# and no directory needed to be created
	return OK


# validation method for public 'save' methods
# this method assumes the directory already exists, call create_directory()
# beforehand on the directory if you are unsure
static func _is_write_operation_path_valid(arg_file_path: String) -> int:
	# check the full path is valid
	var _is_path_valid := false
	# don't log error not finding path if called with force_write
	_is_path_valid = validate_file(arg_file_path)
	# if all was successful,
	return OK if _is_path_valid else ERR_FILE_CANT_WRITE


static func _is_write_operation_valid(arg_file_path: String) -> int:
	var return_code = OK
	var directory_path = arg_file_path.get_base_dir()
	# validate directory path
	return_code = _is_write_operation_directory_valid(directory_path)
	if return_code != OK:
		return return_code
	# validate file path
	return_code = _is_write_operation_path_valid(arg_file_path)
	if return_code != OK:
		return return_code
	# catchall, success exit point
	return return_code


# used to validate that file paths are for valid resource extensions
# pass the file path as an argument
static func _is_resource_extension_valid(arg_resource_file_path: String) -> bool:
	# returns the last x characters from the file path string, where
	# x is the length of the RESOURCE_FILE_EXTENSION constant
	# uses length() as a starting point, subtracts to get starting position
	# of substring then -1 arg returns remaining chars (the constant length)
	var extension =\
			arg_resource_file_path.substr(
			arg_resource_file_path.length()-EXT_RESOURCE.length(),
			-1
			)
	# comparison bool value
	var is_valid_extension = (extension == EXT_RESOURCE)
	if not is_valid_extension:
		GlobalLog.error(null,
				"DataHandler invalid extension, expected {c} but got {e}".format({
					"c": EXT_RESOURCE,
					"e": extension
				}))
	return is_valid_extension


# both the public methods validate_path and validate_directory call this
# private method to actually do things; the methods are similar in execution
# but are different checks, so they are essentially args for this method
static func _validate(
		arg_path: String,
		arg_assert_path: bool,
		arg_is_file: bool
		) -> bool:
	var _is_valid = false
	
	# validate_file call
	if arg_is_file:
		_is_valid = FileAccess.file_exists(arg_path)
	# validate_directory call
	elif not arg_is_file:
		_is_valid = DirAccess.dir_exists_absolute(arg_path)
	
	var log_string = "file" if arg_is_file else "directory"
	
	if arg_assert_path\
	and not _is_valid:
		GlobalLog.error(null,
				"DataHandler _validate"+" (from validate_{m}) ".format({"m": log_string})+\
				"path: [{p}] is not a valid {m}.".format({
					"p": arg_path,
					"m": log_string
				}))
	# this method (and validate_path/validate_directory) will stop project
	# execution if the arg_assert_path parameter is passed a true arg
	if arg_assert_path:
		assert(_is_valid)
	
	# will be true if path existed and was the correct type
	# will be false otherwise
	return _is_valid


##############################################################################

#// ATTENTION DEV
# Further documentation and advice on saving to/loading from disk,
# managing loading etc, can be found at:
#	
#	https://docs.godotengine.org/en/latest/classes/class_configfile.html
#	https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html
#	https://docs.godotengine.org/en/stable/classes/class_resourceloader.html
#	https://docs.godotengine.org/en/stable/classes/class_directory.html
#	https://docs.godotengine.org/en/stable/classes/class_file.html
#	https://github.com/khairul169/gdsqlite
#	https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
#	http://kidscancode.org/godot_recipes/4.x/basics/file_io/
#	https://godotengine.org/qa/21370/what-are-various-ways-that-i-can-store-data

# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html
# [on self-contained mode]
# Self-contained mode is not supported in exported projects yet. To read and
# write files relative to the executable path, use OS.get_executable_path().
# Note that writing files in the executable path only works if the executable
# is placed in a writable location (i.e. not Program Files or another directory
# that is read-only for regular users).


##############################################################################

