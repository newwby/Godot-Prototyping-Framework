#class_name Data
extends Node

##############################################################################

# Loads JSON files from local and user data paths
# Manages DataLoaders that instantiate objects based on JSON data files
# Acts as an API for DataLoaders to fetch new objects from valid data

# CONSIDERATIONS FOR ADDING JSON DATA
# Godot always interprets floats from Json
# Author.Name should be unique for data fetching and storing
# VersionID should match the format "<int>", "<int>.<int>", or "<int>.<int>.<int>"
#	i.e. semantic versioning

#//TODO
# further tests for data loading
# implement dataLoaders that convert valid JSONdata to class objects
# dataLoaders need to contain shadowed methods that can be written to custom instance??
# or use a property set by data mapping (property to data key)
# load from nested directories
# implement user path loading and test
# validate schema values - update schema values to be variant types to match against
#	(or read the schema value? could get false positives against TYPE_INT)

# handling for converting between versions is not implemented
# version converting is trickier to handle

##############################################################################

# var

#const USER_DATA_PATH := "user//data"

# record of all allowed schemas
var schema_register := {}

# data indexed by id_author.id_package.id_name
var data_id_register := {}
# data indexed by schema_id
var data_schema_register := {}
# data indexed by author, package, type, or tag
var data_author_register := {}
var data_package_register := {}
var data_type_register := {}
var data_tag_register := {}

# un-indexed data, recorded in order loaded
# retrieval from this collection will be slower, fetching from registers is preferred
var data_collection: Array = []
# data organised by whether it was loaded from res:// or user://
var local_data_collection: Array = []
var user_data_collection: Array = []

##############################################################################

# virt


func _ready():
	clear_all_data()
	load_all_data()


##############################################################################

# public


# applies data from json structures (using fetch methods) to objects
# for use by develoeprs to create content
func apply_json(given_object: Object, json_data: Dictionary) -> void:
	for data_property in json_data["data"].keys():
		if data_property in given_object:
			given_object.set(data_property, json_data["data"][data_property])


# empties the GlobalData register and reloads everything from a blank slate
# call with caution - loading from disk at runtime could be intensive
#	depending on user data
func clear_all_data() -> void:
	schema_register.clear()
	data_collection.clear()
	local_data_collection.clear()
	user_data_collection.clear()
	data_id_register.clear()
	data_author_register.clear()
	data_package_register.clear()
	data_schema_register.clear()
	data_type_register.clear()
	data_tag_register.clear()


func fetch_by_author(data_author: String) -> Array:
	var fetched_output = _fetch_data_list(data_author, data_author_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find data_author {0} in data_author_register".\
				format([data_author]))
	return fetched_output


func fetch_by_id(data_id: String) -> Dictionary:
	var data_id_components := data_id.split(".")
	if data_id_components.size() != 3:
		Log.warning(self, "cannot parse data_id - {0} - expected [id_author].[id_package].[id_name]".format([data_id]))
		return {}
	
	var fetched_output = _fetch_data(data_id, data_id_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find data_id {0} in data_id_register".\
				format([data_id]))
	return fetched_output


func fetch_by_package(package_id: String) -> Array:
	var fetched_output = _fetch_data_list(package_id, data_package_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find package_id {0} in data_package_register".\
				format([package_id]))
	return fetched_output


func fetch_by_schema(schema_id: String) -> Array:
	var fetched_output = _fetch_data_list(schema_id, data_schema_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find schema_id {0} in data_schema_register".\
				format([schema_id]))
	return fetched_output


func fetch_by_type(data_type: String) -> Array:
	var fetched_output = _fetch_data_list(data_type, data_type_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find data_type {0} in data_type_register".\
				format([data_type]))
	return fetched_output


func fetch_by_tag(data_tag: String) -> Array:
	var fetched_output = _fetch_data_list(data_tag, data_tag_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find data_tag {0} in data_tag_register".\
				format([data_tag]))
	return fetched_output


func get_available_schema_versions(schema_id: String) -> void:
	var all_versions := []
	if schema_id in schema_register.keys():
		var schema_structure = schema_register[schema_id]
		if typeof(schema_structure) == TYPE_DICTIONARY:
			all_versions = schema_structure.keys()
			return
	# else
	Log.error(self, "cannot find schema_id '{0}' in schema_register".format([schema_id]))


func get_available_tags() -> Array:
	return data_tag_register.keys()


func get_available_types() -> Array:
	return data_type_register.keys()


# ProjectSetting can be changed by developer to determine the data directory
#	searched inside res:// and user:// (name consistent across both)
func get_local_data_path() -> String:
	return "res://{0}".\
		format([ProjectSettings.get_setting(GPFPlugin.get_data_path_setting())])


# ProjectSetting can be changed by developer to determine the data directory
#	searched inside res:// and user:// (name consistent across both)
func get_user_data_path() -> String:
	return "user://{0}".\
		format([ProjectSettings.get_setting(GPFPlugin.get_data_path_setting())])


# all schema should be loaded before any data
func load_all_data() -> void:
	verify_user_data_directory()
	var local_path := get_local_data_path()
	var user_path := get_user_data_path()
	_load_schema(local_path)
	_load_schema(user_path)
	_load_all_json_data(local_path)
	_load_all_json_data(user_path)


# if user data doesn't contain the valid directories, create them
func verify_user_data_directory() -> void:
	var user_path = get_user_data_path()
	var user_dir = DirAccess.open(user_path)
	if not user_dir:
		DirAccess.make_dir_recursive_absolute(user_path)
	var schema_path := "{0}/{1}".format([user_path, "_schema"])
	var schema_dir = DirAccess.open(schema_path)
	if not schema_dir:
		DirAccess.make_dir_recursive_absolute(schema_path)


##############################################################################

# private


# returns an internal array from an indexed register
# returns empty array if cannnot be found or any argument is invalid
func _fetch_data(key: String, register: Dictionary) -> Dictionary:
	if register.is_empty():
		return {}
	elif register.has(key):
		var outp_data = register[key]
		if (typeof(outp_data) == TYPE_DICTIONARY):
			return outp_data
		else:
			return {}
	else:
		return {}


# returns a json data value from an indexed register
# returns empty array if cannnot be found or any argument is invalid
func _fetch_data_list(key: String, register: Dictionary) -> Array:
	if register.is_empty():
		return []
	elif register.has(key):
		var outp_data = register[key]
		if (typeof(outp_data) == TYPE_ARRAY):
			return outp_data
		else:
			return []
	else:
		return []


# returns empty array on failure
func _get_all_paths(target_directory: String) -> PackedStringArray:
	# validation
	if target_directory.is_absolute_path() == false:
		Log.warning(self, "invalid file path given to get_all_paths")
		return PackedStringArray([])
	# otherwise
	var result: PackedStringArray
	var dir = DirAccess.open(target_directory)
	if dir:
		dir.list_dir_begin()
		var filename := dir.get_next()
		
		while filename != "":
			# iterate through all directories
			# skip current directory, parent directory, and schema directory
			if dir.current_is_dir() and filename != "." and filename != ".." and filename != "_schema":
				result += _get_all_paths("{0}/{1}".format([target_directory, filename]))
			# file handling
			elif not dir.current_is_dir():
				# if is a valid json file, this can be loaded later
				if filename.ends_with(".json"):
					result.append("{0}/{1}".format([target_directory, filename]))
			# start loop over with next file
			filename = dir.get_next()
		return result
	else:
		Log.error(self, "Failed to start recursive load at target directory: {0}".format([target_directory]))
		return PackedStringArray([])


# json_data should be verified, the return arg of _process_json_data
func _index_data(json_data: Dictionary) -> void:
	# validate
	if json_data.is_empty():
		Log.error(self, "data not verified -> {0}".format([json_data]))
		return
	
	var author = json_data["id_author"]
	var package = json_data["id_package"]
	
	# index by id_author.id_package.id_name
	var id = "{0}.{1}.{2}".format([author, package, json_data["id_name"]])
	data_id_register[id] = json_data
	
	# index by schema_id
	var schema_id = json_data["schema_id"]
	if data_schema_register.has(schema_id) == false:
		data_schema_register[schema_id] = []
	data_schema_register[schema_id].append(json_data)
	
	# index by author
	if data_author_register.has(author) == false:
		data_author_register[author] = []
	data_author_register[author].append(json_data)
	
	# index by package
	if data_package_register.has(package) == false:
		data_package_register[package] = []
	data_package_register[package].append(json_data)
	
	# index by type
	var type = json_data["type"]
	if data_type_register.has(type) == false:
		data_type_register[type] = []
	data_type_register[type].append(json_data)
	
	# index by tag
	var tags = json_data["tags"]
	if typeof(tags) == TYPE_ARRAY:
		if tags.is_empty() == false:
			for tag in tags:
				if data_tag_register.has(tag) == false:
					data_tag_register[tag] = []
				data_tag_register[tag].append(json_data)


# loads every JSON data file in given directory
func _load_all_json_data(target_directory: String) -> void:
	for path in _get_all_paths(target_directory):
		# verify and index the data
		var verified_data = _process_json_data(path)
		if (verified_data.is_empty() == false):
			# store under data collections
			# all
			data_collection.append(verified_data)
			# by location
			if path.begins_with("res://"):
				local_data_collection.append(verified_data)
			elif path.begins_with("user://"):
				user_data_collection.append(verified_data)
			# store data in registers according to data structure
			_index_data(verified_data)


func _load_schema(schema_file_path: String) -> void:
	# schema directory should be inside the path (local or user)
	var schema_sub_directory = "{0}/_schema".format([schema_file_path])
	var dir = DirAccess.open(schema_sub_directory)
	if dir:
		dir.list_dir_begin()
		var filename := dir.get_next()
		while filename != "":
			var filename_no_ext = filename.replace(".json", "")
			if not dir.current_is_dir() and filename.ends_with(".json"):
				var path := "{0}/{1}".format([schema_sub_directory, filename])
				var file := FileAccess.open(path, FileAccess.READ)
				if file:
					var json := JSON.new()
					if json.parse(file.get_as_text()) != OK:
						Log.warning(self, "Invalid JSON in {0}".format([filename_no_ext]))
					else:
						# schema_register is organised as
						# { schema_id:
						#		version id: {...},
						#		version id: {...}
						# }
						var schema_file = json.data
						if _verify_schema_structure(schema_file) == false:
							Log.warning(self, "structure mistmatch for file at {0}".format(schema_file_path))
							return
						# setup schema_register entry for the schema
						if schema_register.has(filename_no_ext) == false:
							schema_register[filename_no_ext] = {}
						# sort versions into the schema_register
						for key in schema_file:
							schema_register[filename_no_ext][key] = schema_file[key]
			filename = dir.get_next()
	else:
		Log.error(self, "cannot find _schema path at {0}".format([schema_file_path]))


# loads json data file from path
# verifies the structure of the data follows expected structure
# verifies the structure of the data matches the specified schema
# appends path to the json data structure
func _process_json_data(json_file_path: String) -> Dictionary:
	# verify args
	if json_file_path.is_absolute_path() == false:
		Log.warning(self, "invalid path in _process_json_data : {0}".format([json_file_path]))
		# ERR_FILE_CANT_OPEN
		return {}
	if json_file_path.ends_with(".json") == false:
		Log.warning(self, "path is not json path : {0}".format([json_file_path]))
		# ERR_FILE_CANT_OPEN
		return {}
	#if filename.is_valid_filename() == false:
		#Log.warning(self, "invalid filemame in _process_json_data : {0}".format([json_file_path]))
		# ERR_FILE_CANT_OPEN
		#return {}
	# valid
	#var path := "{0}/{1}".format([json_file_path, filename])
	var file := FileAccess.open(json_file_path, FileAccess.READ)
	
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			Log.warning(self, "Invalid JSON in {0}.".format([json_file_path]))
			# ERR_FILE_CANT_READ
			return {}
		else:
			var json_data = json.data
			# validate variant typing
			if (typeof(json_data) != TYPE_DICTIONARY):
				Log.warning(self, "unexpected typing verified json data at {0}".format([json_file_path]))
				# ERR_FILE_CANT_READ
				return {}
			# validate data matches schema specified
			if _verify_schema_match(json_data) == false:
				Log.warning(self, "cannot find schema specified for -> {0}".format([json_file_path]))
				# ERR_FILE_CANT_READ
				return {}
			else:
				# OK
				json_data["path"] = json_file_path
				return json_data
	else:
		Log.warning(self, "Could not open file at {0}.".format([json_file_path]))
		# ERR_FILE_CANT_OPEN
		return {}


# schema is loaded into schema_register with the key as the file name of the schema file
# e.g. core.json as schema_register[core]
# this is the schema_id checked in the data
# the top-level key inside the schema file is the schema_version checked in data
# it is stored nested inside the schema_register entry
# e.g. "1.0" in core.json will be stored as schema_register[core][1.0]
# this allows for multiple versions of the same schema stored in one file
func _verify_schema_match(json_data: Dictionary) -> bool:
	var valid_json_data = true
	
	# these keys must match the following types in all data entries
	# everything inside the data value is customisable
	var mandatory_kv_pairs := {
		"schema_id": TYPE_STRING,
		"schema_version": TYPE_STRING,
		"id_author": TYPE_STRING,
		"id_package": TYPE_STRING,
		"type": TYPE_STRING,
		"tags": TYPE_ARRAY,
		"data": TYPE_DICTIONARY,
	}
	
	for key in mandatory_kv_pairs:
		if json_data.has(key) == false:
			Log.warning(self, "missing key for {0} on {1}".format([key, json_data]))
			valid_json_data = false
			break
		if typeof(json_data[key]) != mandatory_kv_pairs[key]:
			Log.warning(self, "invalid value type for {0} on {1}".format([key, json_data]))
			valid_json_data = false
			break
	
	if valid_json_data == false:
		return false
	
	var schema_id = json_data["schema_id"]
	var schema_version = json_data["schema_version"]
	var interior_data = json_data["data"]
	
	# check if schema has already been registered in _load_schema
	var valid_schema
	# if version code is blank, schema validation is skipped
	if schema_id == "":
		return true 
	elif schema_register.has(schema_id) == false:
		Log.warning(self, "cannot find schema {0} in register".format([schema_id, schema_version]))
		return false
	else:
		if schema_register[schema_id].has(schema_version) == false:
			Log.warning(self, "schema {0} found in register but not version {1}".format([schema_id, schema_version]))
			return false
		else:
			valid_schema = schema_register[schema_id][schema_version]
			
			# check data matches schema keys and typing
			# data can contain keys/value pairs not specified in the schema,
			#	but these keys/values willl not be type verified
			if typeof(valid_schema) == TYPE_DICTIONARY:
				for schema_key in valid_schema:
					if interior_data.has(schema_key) == false:
						Log.warning(self, "data missing key {0} in {1}".format([schema_key, json_data]))
						return false
					# check value typing
					var data_value = interior_data[schema_key]
					var data_type = typeof(data_value)
					var schema_value = valid_schema[schema_key]
					var schema_type = typeof(schema_value)
					if data_type != schema_type:
						Log.warning(self, "data typing mismatch, {0}: {1} (type {2}) is invalid. Expected type {3}".\
								format([schema_key, data_value, data_type, schema_type]))
			# else
			return true
	
	Log.warning(self, "cannot find schema for {0}.{1}".format([schema_id, schema_version]))
	return false


# all entry structure should match
# string : dictionary
# where the string key is 1-3 integers separated by periods.
# i.e. 1.0.1, 2.0, or 4
#func _verify_schema(schema_data: Dictionary) -> bool:
	#return true
func _verify_schema_structure(schema_data: Dictionary) -> bool:
	for key in schema_data.keys():
		# Check if the key is a valid format, type or string in specific regex format
		# Regex ensures the key is 1-3 numeric sections separated by periods
		#	Example matches: "1", "2.0", "3.5.2" (but not "1.2.3.4" or "a.b.c")
		var valid_format =\
				key.is_valid_int() or\
				key.is_valid_float() or\
				key.match("^\\d+(\\.\\d+){0,2}$")
		if not valid_format:
			Log.warning(self, "Invalid key format: {0}".format([key]))
			return false
		
		# Check if the value is a dictionary
		if typeof(schema_data[key]) != TYPE_DICTIONARY:
			Log.warning(self, "Invalid value for key: {0}".format([key]))
			return false
	
	return true
