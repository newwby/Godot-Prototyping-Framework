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

# un-indexed data, recorded in order loaded
# retrieval from this collection will be slower, fetching from registers is preferred
var data_collection: Array = []

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
	#//TODO add indexing registers once implemented


func fetch_by_id(data_id: String) -> Dictionary:
	var data_id_components := data_id.split(".")
	if data_id_components.size() != 3:
		Log.warning(self, "cannot parse data_id - {0} - expected \"id_author\".\"id_package\".\"id_name\" ".format([data_id]))
		return {}
	#var data_author = data_id_components[0]
	#var data_package = data_id_components[1]
	#var data_name = data_id_components[2]
	if data_id_register.has(data_id):
		var outp_data = data_id_register[data_id]
		if (typeof(outp_data) == TYPE_DICTIONARY):
			return outp_data
	# else
	Log.warning(self, "cannot find data_id {0}".format([data_id]))
	return {}

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
						var schema_file = json.data
						if schema_register.has(filename_no_ext) == false:
							schema_register[filename_no_ext] = {}
						for key in schema_file:
							schema_register[filename_no_ext][key] = schema_file[key]
			filename = dir.get_next()
	else:
		Log.error(self, "cannot find _schema path at {0}".format([schema_file_path]))


# schema is loaded into schema_register with the key as the file name of the schema file
# e.g. core.json as schema_register[core]
# this is the schema_id checked in the data
# the top-level key inside the schema file is the schema_version checked in data
# it is stored nested inside the schema_register entry
# e.g. "1.0" in core.json will be stored as schema_register[core][1.0]
# this allows for multiple versions of the same schema stored in one file
func _verify_schema(json_data: Dictionary) -> bool:
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


# loads every JSON data file in given directory
func _load_all_json_data(target_directory: String) -> void:
	for path in _get_all_paths(target_directory):
		# verify and index the data
		var verified_data = _verify_json_data(path)
		if (verified_data.is_empty() == false):
			data_collection.append(verified_data)
			_index_data(verified_data)


func _index_data(json_data: Dictionary) -> void:
	# index by id_author.id_package.id_name
	var id = "{0}.{1}.{2}".format([
		json_data["id_author"],
		json_data["id_package"],
		json_data["id_name"]
	])
	data_id_register[id] = json_data


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


func _verify_json_data(json_file_path: String) -> Dictionary:
	# verify args
	if json_file_path.is_absolute_path() == false:
		Log.warning(self, "invalid path in _verify_json_data : {0}".format([json_file_path]))
		# ERR_FILE_CANT_OPEN
		return {}
	#if filename.is_valid_filename() == false:
		#Log.warning(self, "invalid filemame in _verify_json_data : {0}".format([json_file_path]))
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
			if _verify_schema(json_data) == false:
				Log.warning(self, "cannot find schema specified for -> {0}".format([json_file_path]))
				# ERR_FILE_CANT_READ
				return {}
			else:
				# OK
				return json_data
	else:
		Log.warning(self, "Could not open file at {0}.".format([json_file_path]))
		# ERR_FILE_CANT_OPEN
		return {}
