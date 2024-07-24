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

# file extension for text resource files
const EXT_RESOURCE := ".tres"

##############################################################################

# public methods


#static func clean_file_name(arg_file_name: String) -> String:
	#return arg_file_name.replace("/[/\\?%*:|\"<>]/g", '-')


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
# can search recursively, returning all nested directories
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



# This method gets the file path for every file in a directory and returns
# those file paths within an array. Caller can then use those file paths
# to query file types or load files.
static func get_file_paths(arg_directory_path: String) -> PackedStringArray:
	# validate path
	var file_name := ""
	var return_arg_file_paths: PackedStringArray = []
	
	var dir_access := DirAccess.open(arg_directory_path)
	# find the directory, loop through the directory
	if dir_access.get_open_error() == OK:
		# skip if directory couldn't be opened
		if dir_access.list_dir_begin()  != OK:# TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			return return_arg_file_paths
		# find first file in directory, prep validation bool, and start
		file_name = dir_access.get_next()
		while file_name != "":
			# check isn't a directory (i.e. is a file)
			if not dir_access.current_is_dir():
				# set validation default value
				return_arg_file_paths.append(arg_directory_path+"/"+file_name)
				# if they didn't, nothing is appended
			# end of loop
			# get next file
			file_name = dir_access.get_next()
		dir_access.list_dir_end()
#	print("returning return_arg_file_paths@ ", return_arg_file_paths)
	return return_arg_file_paths


# this method loads and returns (if valid) a resource from disk
# returns either a loaded resource, or a null value if it is invalid
# [method params as follows]
##1, arg_file_path, is the path to the resource to be loaded.
##2, type_cast, should be comparison type or object of a class to be compared
# to the resource once it is loaded. If the comparison returns untrue, the
# loaded resource will not be returned. The default argument for this parameter
# is null, which will result in this comparison behvaiour being ignored.
# Developers can use this to ensure the resource they're loading will return
# a resource of the class they desire.
# [warning!] Devs, if using a var referencing an object as a comparison class
# class, be careful not to use an object that shares a common parent but isn't
# the same end point class (example would be HBoxContainer and VBoxContainer
# both sharing many of the same parents), as this may return false postiives.

#//TODO remove or rewrite load_resource due to arg_type_cast no longer working
#	and the behaviour inside being base ResourceLoader static functionality
#static func load_resource(
		#arg_file_path: String,
		#arg_type_cast = null
		#):
	## add type hint to load?
##	var type_hint = ""
##	if type_cast is Resource\
##	and "get_class" in type_cast:
##			type_hint = str(type_cast.get_class())
		#
	## check path is valid before loading resource
	#var is_path_valid = validate_file(arg_file_path)
	#if not is_path_valid:
		#GlobalLog.error(self,
				#"attempted to load non-existent resource at {p}".format({
					#"p": arg_file_path
				#}))
		#return null
	#
		## attempt to load resource
	#var new_resource: Resource = ResourceLoader.load(arg_file_path)
	#
	## then validate it was loaded and is corrected type
	#
	## if resource wasn't succesfully loaded (check before type validation)
	#if new_resource == null:
		#GlobalLog.error(self,
				#"resource not loaded successfully, is null")
		#return null
	#
	## ignore type_casting behaviour if set to null
	## otherwise loaded resource must be the same type
	#if not (arg_type_cast == null):
		#if not (new_resource is arg_type_cast):
			## discard value to ensure reference count update
			#new_resource = null
			#GlobalLog.error(self,
					#"resource not loaded succesfully, invalid type")
			#return null
	#
	## if everything is okay, return the loaded resource
	## elevated log only
	#GlobalLog.info(self,
			#"resource {res} validated and returned".format({
				#"res": new_resource
			#}), true)
	#return new_resource



# method to save any resource or resource-extended custom class to disk.
# call this method with 'if save_resource(*args) == OK' to validate
# if called on a non-existing file or path it will write the entire path
## if arg_backup is specified, any previous file found will be moved to a
##	separate file with the 'BACKUP_SUFFIX' added to its file name
static func save_resource(
		arg_file_path: String,
		arg_saveable_res: Resource,
		arg_backup : bool = false
		) -> int:
	# split directory path and file path
	var directory_path = arg_file_path.get_base_dir()
	var file_and_ext = arg_file_path.get_file()
	if (directory_path+"/"+file_and_ext) != arg_file_path:
		return ERR_FILE_BAD_PATH
	
	var return_code: int = OK
	# check can write
	return_code = _is_write_operation_valid(arg_file_path)
	if return_code != OK:
		GlobalLog.error(null, "DataHandler invalid write operation at"+str(arg_file_path))
		return return_code
		
	
	# validate write extension is valid
	if not _is_resource_extension_valid(arg_file_path):
		# _is_resource_extension_valid already includes logging, redundant
#		GlobalLog.error(self,
#				"resource extension invalid")
		return ERR_FILE_CANT_WRITE
	
	# move on to the write operation
	# if file is new, just attempt a write
	if not validate_file(arg_file_path):
		return_code = ResourceSaver.save(arg_saveable_res, arg_file_path)
	# if file already existed, need to safely write to prevent corruption
	# i.e. write to a temporary file, remove the older, make temp the new file
	else:
		# attempt the write operation
		var temp_data_path = directory_path+"temp_"+file_and_ext
		return_code = ResourceSaver.save(arg_saveable_res, temp_data_path)
		# if we wrote the file successfully, time to remove the old file
		# i.e. move previous file to recycle bin/trash
		if return_code == OK:
			# re: issue 67137, OS.move_to_trash will cause a project crash
			# but on this branch the arg_file_path should be validated
			assert(validate_file(arg_file_path, true))
			# move to trash behaviour should only proceed if not backing up
			if arg_backup == false:
				# Note: If the user has disabled trash on their system,
				# the file will be permanently deleted instead.
				var get_global_path =\
						ProjectSettings.globalize_path(arg_file_path)
				return_code = OS.move_to_trash(get_global_path)
				# if file was moved to trash, the path should now be invalid
			# if backing up, the previous file should be moved to backup
			elif arg_backup == true:
				var backup_path = arg_file_path
				# path to file is already validated to have .tres extension
				backup_path = arg_file_path.rstrip(EXT_RESOURCE)
				# concatenate string as backup
				backup_path += BACKUP_SUFFIX
				backup_path += EXT_RESOURCE
				return_code = DirAccess.rename_absolute(arg_file_path, backup_path)
			
			if return_code == OK:
				assert(not validate_file(arg_file_path))
				# rename the temp file to be the new file
				return_code = DirAccess.rename_absolute(
						temp_data_path, arg_file_path)
		# if the temporary file wasn't written successfully
		else:
			return return_code
	
	
	# if all is well and the static function didn't exit prior to this point
	# successful exit points will be
	# 1) path didn't exist and file was written, or
	# 2) path exists, temp file written, first file trashed, temp file renamed
	# return code should be 'OK' (int 0)
	return return_code


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

