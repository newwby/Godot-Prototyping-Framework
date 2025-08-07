@tool
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

#//TODO
# remove .has() & dict[] = value checking/setting in favour of .get/.set

# handling for converting between versions is not implemented
# version converting is trickier to handle

##############################################################################

# var

# these keys must match the following types in all data entries
# everything inside the data value is customisable
var EXPECTED_DATA_STRUCTURE := {
	"schema_id": TYPE_STRING,
	"schema_version": TYPE_STRING,
	"id_author": TYPE_STRING,
	"id_package": TYPE_STRING,
	"id_name": TYPE_STRING,
	"type": TYPE_STRING,
	"tags": TYPE_ARRAY,
	"data": TYPE_DICTIONARY,
}


# all json entries are cached by unique id here
#//TODO .values() replaces data_collection, can deprecate that
#//TODO replaces data_id_register, can deprecate that
#//TODO need to address issue with ids across schema versions not being unique
#	e.g. version 1.1, 1.2 may share an id - this only indexes the last found
#	(store by path or id+schema as UID instead?)
var all_id_map := {}

# record of all allowed schemas
var schema_register := {}

# data indexed by concatenated id (id_author.id_package.id_name)
var data_id_register := {}

# data indexed by schema_id and schema_version - nested, so data is cached as:
#	{"schema_id": {
#		"1.0.0": {...},
#		"1.0.1": {...},
#		"1.1.0": {...},
#		}
#	}
# data indexed by schema_id
var data_schema_register := {}

# data indexed by author, package, type, or tag
var data_author_register := {}
var data_package_register := {}
var data_type_register := {}
var data_tag_register := {}

# data indexed in the same pattern as data_schema_register but with a further
#	 nested value where values are stored, per schema id/version pair, as array
# e.g.
#	{
#	"schema_id": {
#		"1.0.0": {
#			"id_author": [],
#			"id_package": [],
#			"type": [],
#			"tags": [],
#			},
#		"1.0.1": {...},
#		"1.2.0": {...},
#		},
#	"other_schema_id": {...}
#	}
var property_schema_register := {}

# un-indexed data, recorded in order loaded
# retrieval from this collection will be slower, fetching from registers is preferred
var data_collection: Array = []
# data organised by whether it was loaded from res:// or user://
var local_data_collection: Array = []
var user_data_collection: Array = []

##############################################################################

# virt


func _ready():
	# already empty at init.
	# clear_all_data()
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
	all_id_map.clear()
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


# takes an array of strings (or PoolStringArray) and returns as comma
#	separated string
# for converting tags to a readable list
func decode_tags(string_array) -> String:
	# on invalid entry
	if string_array == null:
		return ""
	var arg_type := typeof(string_array)
	if not arg_type in [TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY]:
		Log.error(self, "_decode_tags passed invalid type ({0}) argument: {1}".format(arg_type, string_array))
		return ""
	# else
	var output_string := ""
	var valid_strings := PackedStringArray([])
	for item in string_array:
		if typeof(item) == TYPE_STRING:
			valid_strings.append(item)
	output_string = ", ".join(valid_strings)
	return output_string


# takes a comma separated string and returns it as an array
# for converting a readable tag list back to a dict encoded tag list
func encode_tags(tag_string: String) -> Array:
	var split_tag_string = tag_string.split(",")
	var output_array := []
	for string_value in split_tag_string:
		output_array.append(string_value.strip_edges())
	return output_array


#//TODO implement fetch where can match any one condition (especially for tags)
# will return an array of Json data entries from intersected registers
# the criteria can have the following keys with the expected values
# "id": String (to look up by specific full identifier; author.package.name)
# "id_author": String (to look up by specific author identifier)
# "id_package": String (to look up by specific package identifier)
# "schema_id": String (to look up by specific schema)
# "schema_version": String (to look up by specific version)
# "type": String (to look up by specific type)
# "tags": PackedStringArray (to look up by specific tags, must match all)
func fetch(criteria: Dictionary) -> Array:
	var final_output := []
	var valid_ids := {}
	
	var request_full_id = criteria.get("id", null)
	var request_id_author = criteria.get("id_author", null)
	var request_id_package = criteria.get("id_package", null)
	var request_schema_id = criteria.get("schema_id", null)
	var request_schema_ver = criteria.get("schema_version", null)
	var request_type = criteria.get("type", null)
	var request_tags = criteria.get("tags", [])
	
	if request_full_id != null:
		if all_id_map.has(request_full_id):
			valid_ids[request_full_id] = true
	
	# find ids for data with the given search term
	if (request_id_author != null):
		var valid_author_ids = data_author_register.get(request_id_author, {})
		valid_ids = _intersect_sets(valid_ids, valid_author_ids)
	
	if (request_id_package != null):
		var valid_package_ids = data_package_register.get(request_id_package, {})
		valid_ids = _intersect_sets(valid_ids, valid_package_ids)
	
	if (request_schema_id != null) and (request_schema_ver != null):
		var data_by_schema_vers = data_schema_register.get(request_schema_id, {})
		var valid_schema_ids = data_by_schema_vers.get(request_schema_ver, {})
		valid_ids = _intersect_sets(valid_ids, valid_schema_ids)
	
	if (request_type != null):
		var valid_type_ids = data_type_register.get(request_type, {})
		valid_ids = _intersect_sets(valid_ids, valid_type_ids)
	
	if (request_tags != null):
		if typeof(request_tags) == TYPE_ARRAY\
		or typeof(request_tags) == TYPE_PACKED_STRING_ARRAY:
			for tag in request_tags:
				var new_valid_tag_ids = data_tag_register.get(tag, {})
				valid_ids = _intersect_sets(valid_ids, new_valid_tag_ids)
	
	# get the actual data
	for id in valid_ids.keys():
		if all_id_map.has(id):
			final_output.append(all_id_map[id])
	return final_output


func fetch_by_author(data_author: String) -> Array:
	return fetch({"id_author": data_author})


#//TODO reimplement with fetch logic, return arg and tests need updating
func fetch_by_id(data_id: String) -> Dictionary:
	var data_id_components := data_id.split(".")
	if data_id_components.size() != 3:
		Log.warning(self, "cannot parse data_id - {0} - expected [id_author].[id_package].[id_name]".format([data_id]))
		return {}
	
	#return fetch({
		#"id_author": data_id_components[0],
		#"id_package": data_id_components[1],
		#"id_name": data_id_components[2],
		#})
	
	var fetched_output = _fetch_data_from_register(data_id, data_id_register)
	if fetched_output.is_empty():
		Log.warning(self, "cannot find data_id {0} in data_id_register".\
				format([data_id]))
	return fetched_output


func fetch_by_package(package_id: String) -> Array:
	return fetch({"id_package": package_id})


func fetch_by_schema(schema_id: String, schema_version: String) -> Array:
	return fetch({
		"schema_id": schema_id,
		"schema_version": schema_version,
	})


func fetch_by_type(data_type: String) -> Array:
	return fetch({"type": data_type})


# only searches a singular tag
func fetch_by_tag(data_tag: String) -> Array:
	return fetch({"tags": [data_tag]})


# specify the schema_arguments to search in property_schema_register
func get_available_authors(schema_id: String = "", schema_version: String = "") -> Array:
	if (schema_id == "") and (schema_version == ""):
		return data_author_register.keys()
	else:
		return _get_available_values(schema_id, schema_version, "id_author")


# specify the schema_arguments to search in property_schema_register
func get_available_packages(schema_id: String = "", schema_version: String = "") -> Array:
	if (schema_id == "") and (schema_version == ""):
		return data_package_register.keys()
	else:
		return _get_available_values(schema_id, schema_version, "id_package")


func get_available_schemas() -> Array:
	return schema_register.keys()


func get_available_schema_versions(schema_id: String) -> void:
	var all_versions := []
	if schema_id in schema_register.keys():
		var schema_structure = schema_register[schema_id]
		if typeof(schema_structure) == TYPE_DICTIONARY:
			all_versions = schema_structure.keys()
			return
	# else
	Log.error(self, "cannot find schema_id '{0}' in schema_register".format([schema_id]))


# specify the schema_arguments to search in property_schema_register
func get_available_tags(schema_id: String = "", schema_version: String = "") -> Array:
	if (schema_id == "") and (schema_version == ""):
		return data_tag_register.keys()
	else:
		return _get_available_values(schema_id, schema_version, "tags")


# specify the schema_arguments to search in property_schema_register
func get_available_types(schema_id: String = "", schema_version: String = "") -> Array:
	if (schema_id == "") and (schema_version == ""):
		return data_type_register.keys()
	else:
		return _get_available_values(schema_id, schema_version, "type")


# ProjectSetting can be changed by developer to determine the data directory
#	searched inside res:// and user:// (name consistent across both)
func get_local_data_path() -> String:
	return "res://{0}".\
		format(["data"])


# ProjectSetting can be changed by developer to determine the data directory
#	searched inside res:// and user:// (name consistent across both)
func get_user_data_path() -> String:
	return "user://{0}".\
		format(["data"])


# used in process_json_data
# exposed for testing purposes
func is_valid_json_data(json_data: Dictionary) -> int:
	# validate variant typing
	if (typeof(json_data) != TYPE_DICTIONARY):
		return ERR_INVALID_PARAMETER
		Log.warning(self, "unexpected typing verified")
		return ERR_FILE_CANT_READ
	# validate data matches schema specified
	if _verify_schema_match(json_data) == false:
		var schema_id = json_data.get("schema_version", null)
		Log.warning(self, "cannot find schema '{0}' specified".format([schema_id]))
		return ERR_FILE_UNRECOGNIZED
	else:
		return OK


# all schema should be loaded before any data
func load_all_data() -> void:
	verify_user_data_directory()
	var local_path := get_local_data_path()
	var user_path := get_user_data_path()
	_load_schema(local_path)
	_load_schema(user_path)
	_load_all_json_data(local_path)
	_load_all_json_data(user_path)


# simplifies common call
func reload_data() -> void:
	clear_all_data()
	load_all_data()


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
func _fetch_data_from_register(key: String, register: Dictionary) -> Dictionary:
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
func _fetch_data_list_from_register(key: String, register: Dictionary) -> Array:
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


# used in 'get_available' methods
func _get_available_values(schema_id: String, schema_version: String, key: String) -> Array:
	var all_schema_versions = property_schema_register.get(schema_id, {})
	var all_schema_values = all_schema_versions.get(schema_version, {})
	var desired_schema_values = all_schema_values.get(key, [])
	if typeof(desired_schema_values) == TYPE_ARRAY:
		return desired_schema_values
	else:
		return []


func _index_data(json_data: Dictionary) -> void:
	# json_data should be verified, the return arg of _process_json_data
	if json_data.is_empty():
		Log.error(self, "data not verified -> {0}".format([json_data]))
		return
	
	# data is cached in the all_id_map using full id as key
	# data is indexed to separate registers by full id
	# lookups use intersections of the different registers before looking up
	#	the actual id values in all_id_map
	#//TODO this is time bounded by the smallest register, if caching a
	#	significant number of records could run into lookup lags
	
	var id_author = json_data.get("id_author", null)
	var id_package = json_data.get("id_package", null)
	var id_name = json_data.get("id_name", null)
	var full_id = "{0}.{1}.{2}".format([id_author, id_package, id_name])
	# cache by id
	all_id_map[full_id] = json_data
	
	var schema_id = json_data.get("schema_id", null)
	var schema_ver = json_data.get("schema_version", null)
	
	if data_schema_register.has(schema_id) == false:
		data_schema_register[schema_id] = {}
	if data_schema_register[schema_id].has(schema_ver) == false:
		data_schema_register[schema_id][schema_ver] = {}
	# index by schema id/version
	data_schema_register[schema_id][schema_ver][full_id] = true
	
	# index by author
	if data_author_register.has(id_author) == false:
		data_author_register[id_author] = {}
	data_author_register[id_author][full_id] = true
	# index by package
	if data_package_register.has(id_package) == false:
		data_package_register[id_package] = {}
	data_package_register[id_package][full_id] = true
	
	# index by type
	var type = json_data.get("type", null)
	if data_type_register.has(type) == false:
		data_type_register[type] = {}
	data_type_register[type][full_id] = true
	
	# index by tag
	var tags = json_data.get("tags", [])
	for tag in tags:
		if data_tag_register.has(tag) == false:
			data_tag_register[tag] = {}
		data_tag_register[tag][full_id] = true
	
	# assign property_schema_register values
	#_index_by_schema(schema_id, schema_ver, id_author, id_package, type, tags)
	# initially confirm property_schema_register structure
	if property_schema_register.has(schema_id) == false:
		property_schema_register[schema_id] = {}
	if property_schema_register[schema_id].has(schema_ver) == false:
		property_schema_register[schema_id][schema_ver] = {}
		
	var schema_entry = property_schema_register[schema_id][schema_ver]
	# update
	if schema_entry.has("id_author") == false:
		schema_entry["id_author"] = []
	if schema_entry["id_author"].has(id_author) == false:
		schema_entry["id_author"].append(id_author)
	
	if schema_entry.has("id_package") == false:
		schema_entry["id_package"] = []
	if schema_entry["id_package"].has(id_package) == false:
		schema_entry["id_package"].append(id_package)
	
	if schema_entry.has("type") == false:
		schema_entry["type"] = []
	if schema_entry["type"].has(type) == false:
		schema_entry["type"].append(type)
	
	if schema_entry.has("tags") == false:
		schema_entry["tags"] = []
	for tag in tags:
		if schema_entry["tags"].has(tag) == false:
			schema_entry["tags"].append(tag)


# must be in both dicts to survive
# time bounded by lowest size dict
func _intersect_sets(_a: Dictionary, _b: Dictionary) -> Dictionary:
	var _a_empty = _a.is_empty()
	var _b_empty = _b.is_empty()
	
	if _a_empty and not _b_empty:
		return _b
	elif _b_empty and not _a_empty:
		return _a
	elif _a_empty and _b_empty:
		return {}
	
	var bigger_dict := {}
	var smaller_dict := {}
	if _a.keys().size() >= _b.keys().size():
		bigger_dict = _a.duplicate(true)
		smaller_dict = _b.duplicate(true)
	else:
		bigger_dict = _b.duplicate(true)
		smaller_dict = _a.duplicate(true)
	
	for x in smaller_dict.keys():
		if not x in bigger_dict.keys():
			smaller_dict.erase(x)
	return smaller_dict


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
			#//TODO undo this temp for testing
			#_index_data(verified_data)
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
	
	var file := FileAccess.open(json_file_path, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			Log.warning(self, "Invalid JSON in {0}.".format([json_file_path]))
			# ERR_FILE_CANT_READ
			return {}
		else:
			var json_data = json.data
			var is_valid := is_valid_json_data(json_data)
			if is_valid == OK:
				# remember the file path
				json_data["path"] = json_file_path
				return json_data
			else:
				Log.warning(self, "error {0} on processing {1}".format([is_valid, json_file_path]))
				return {}
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
	
	for key in EXPECTED_DATA_STRUCTURE:
		if json_data.has(key) == false:
			Log.warning(self, "missing key for {0} on {1}".format([key, json_data]))
			valid_json_data = false
			break
		if typeof(json_data[key]) != EXPECTED_DATA_STRUCTURE[key]:
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
						Log.warning(self, "data missing key '{0}' in {1}".format([schema_key, json_data]))
						return false
					# check value typing
					var data_value = interior_data[schema_key]
					var data_type = typeof(data_value)
					var schema_value = valid_schema[schema_key]
					var schema_type = typeof(schema_value)
					if data_type != schema_type:
						Log.warning(self, "data typing mismatch, {0}: {1} (type {2}) is invalid. Expected type {3}".\
								format([schema_key, data_value, data_type, schema_type]))
						return false
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


########################################################
