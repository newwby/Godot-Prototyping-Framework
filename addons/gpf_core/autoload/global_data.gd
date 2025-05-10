# className enabled for testing
class_name CardEngine
extends Node

##############################################################################

# Singleton that manages the card runtime
# Loads card data at runtime and indexes by id/name/tag
# Propagates signals

##############################################################################

# var

#//TODO make into project exports
const LOCAL_DATA_PATH := "res://data"
#const USER_DATA_PATH := "user//data"

# record of all allowed schemas
var schema_register := {}
# un-indexed data, recorded in order loaded
var data_register: Array = []

##############################################################################

# virt

func _ready():
	_load_schema(LOCAL_DATA_PATH)
	_load_json_data(LOCAL_DATA_PATH)
	#_load_json_data(USER_DATA_PATH)

##############################################################################

# public

##############################################################################

# private


func _load_schema(arg_path: String) -> void:
	# schema directory should be inside the path (local or user)
	var schema_sub_directory = "{0}/schema".format([arg_path])
	var dir = DirAccess.open(schema_sub_directory)
	if dir:
		dir.list_dir_begin()
		var filename := dir.get_next()
		var filename_no_ext = filename.replace(".json", "")
		while filename != "":
			if not dir.current_is_dir() and filename.ends_with(".json"):
				var path := "{0}/{1}".format([schema_sub_directory, filename])
				var file := FileAccess.open(path, FileAccess.READ)
				if file:
					var json := JSON.new()
					if json.parse(file.get_as_text()) != OK:
						print("json error -> ", json.get_error_line())
						push_warning("Invalid JSON in %s" % filename)
					else:
						var schema_file = json.data
						if schema_register.has(filename_no_ext) == false:
							schema_register[filename_no_ext] = {}
						for key in schema_file:
							schema_register[filename_no_ext][key] = schema_file[key]
			filename = dir.get_next()


#//TODO validate schema values
# schema is loaded into schema_register with the key as the file name of the schema file
# e.g. core.json as schema_register[core]
# this is the version_code checked in the data
# the top-level key inside the schema file is the version_id checked in data
# it is stored nested inside the schema_register entry
# e.g. "1.0" in core.json will be stored as schema_register[core][1.0]
# this allows for multiple versions of the same schema stored in one file
#//TODO handling for converting between versions is not implemented
func _verify_schema(json_data: Dictionary) -> bool:
	var valid_json_data = true
	
	# these five keys must match the following types in all data entries
	# everything inside the data value is customisable
	var mandatory_kv_pairs := {
		"version_code": TYPE_STRING,
		"version_id": TYPE_STRING,
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
	
	var version_code = json_data["version_code"]
	var version_id = json_data["version_id"]
	var interior_data = json_data["data"]
	
	var valid_schema
	if schema_register.has(version_code):
		if schema_register[version_code].has(version_id):
			valid_schema = schema_register[version_code][version_id]
			if typeof(valid_schema) == TYPE_DICTIONARY:
				for key in valid_schema:
					if interior_data.has(key) == false:
						Log.warning(self, "data missing key {0} in {1}".format([key, json_data]))
						return false
			# else
			return true
	
	Log.warning(self, "cannot find schema!")
	return false


func _load_json_data(arg_path: String) -> void:
	var dir = DirAccess.open(arg_path)
	if dir:
		dir.list_dir_begin()
		var filename := dir.get_next()
		while filename != "":
			if not dir.current_is_dir() and filename.ends_with(".json"):
				var path := "{0}/{1}".format([arg_path, filename])
				var file := FileAccess.open(path, FileAccess.READ)
				if file:
					var json := JSON.new()
					if json.parse(file.get_as_text()) != OK:
						print("json error -> ", json.get_error_line())
						push_warning("Invalid JSON in %s" % filename)
					else:
						var json_data = json.data
						if _verify_schema(json_data) == false:
							print("invalid schema for -> ".format([json_data]))
						if json_data.has("data"):
							data_register.append(json_data)
						else:
							push_warning("Missing 'data' key in %s" % filename)
			filename = dir.get_next()
	else:
		push_error("Failed to open directory")
