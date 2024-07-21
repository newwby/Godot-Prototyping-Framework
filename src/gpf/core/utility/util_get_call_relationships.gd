extends Node

##############################################################################

# [PURPOSE]
# script to find every custom class referenced by every script
# useful for understanding relationships between your scripts in large projects

# [KNOWN LIMITATIONS]
# does not return inbuilt classes as of right now, edit/extend (in
#	_get_all_class_names) to add classDB classes if functionality needed
# only works with gdscript files right now, edit/extend to add other script
#	extensions (in _get_gdscript_paths) if functionality required

# [USE]
# use this script by attaching it to any node and running the scene
#	OR call main() from an instance of this script

##############################################################################

#//TODO

# ignore own class_name
# check inbuilt classes
# check non-gdscript(.gd) classes
# count number of times a class name appears in a script
# include singleton names?

##############################################################################

# view in inspector for script output
var script_class_instances = {}

##############################################################################

# virtual


func _ready():
	main()


##############################################################################

# public


# returns all custom class names (from project settings) as PoolStringArray
func main():
	# prepwork
	var all_class_names: PackedStringArray = _get_all_class_names()
	var all_files: PackedStringArray = _get_all_files()
	var all_gdscript_paths: Array = _get_gdscript_paths(all_files)
	var loaded_scripts: Dictionary = _get_loaded_scripts(all_gdscript_paths)
	# main functionality
	_read_call_relationships(loaded_scripts, all_class_names)


##############################################################################

# private


# returns all custom class names (from project settings) as PoolStringArray
func _get_all_class_names() -> PackedStringArray:
	var class_names: PackedStringArray = []
	var class_dict = ProjectSettings.get_setting("_global_script_classes")
	var class_entry_as_dict := {}
	for class_entry in class_dict:
		if typeof(class_entry) == TYPE_DICTIONARY:
			class_entry_as_dict = class_entry
		if class_entry_as_dict.has("class"):
			class_names.append(class_entry_as_dict["class"])
	return class_names


# returns all file paths in res://
func _get_all_files() -> PackedStringArray:
	var all_files: PackedStringArray = []
	var all_local_dir_paths: Array = GlobalData.get_dir_paths("res://", true)
	for dirpath in all_local_dir_paths:
		var get_files: PackedStringArray = GlobalData.get_file_paths(dirpath)
		if get_files != null:
			all_files.append_array(get_files)
	return all_files


# pass return value from _get_all_files as argument
# returns only file paths for gdscript files in res://
func _get_gdscript_paths(arg_all_files: PackedStringArray) -> Array:
	var all_gdscript_paths: Array = []
	var path_as_string: String
	for file_path in arg_all_files:
		path_as_string = str(file_path)
		if path_as_string.get_extension() == "gd":
			all_gdscript_paths.append(path_as_string)
	return all_gdscript_paths


# pass return value from _get_gdscript_paths as argument
# returns organised dict of {script_name: script_object}
func _get_loaded_scripts(arg_gdscript_paths) -> Dictionary:
	var loaded_scripts: Dictionary = {}
	var script_name := ""
	var script_load_attempt: Script = null
	for gdpath in arg_gdscript_paths:
		if GlobalData.validate_file(gdpath):
			script_load_attempt = load(gdpath)
			if script_load_attempt != null:
				if typeof(gdpath) == TYPE_STRING:
					script_name = gdpath.get_file()
				else:
					script_name = str(gdpath)
				loaded_scripts[script_name] = script_load_attempt
	return loaded_scripts


# main functionality, updates the script_class_instances property (which can
#	be viewed in editor) and outputs said property to console log
# requires the output value of _get_loaded_scripts as first argument, and
#	the output value of _get_all_class_names as second argument.
func _read_call_relationships(
		arg_loaded_scripts: Dictionary,
		arg_class_names) -> void:
	var script_source_code := []
	var script_file: Script = null
	for script_file_key in arg_loaded_scripts.keys():
		script_file = arg_loaded_scripts[script_file_key]
		if script_file != null:
			# split source code by line
			script_source_code = script_file.source_code.split("\n")
			for line in script_source_code:
				if str(line).begins_with("extends")\
				or str(line).begins_with("#")\
				or str(line).begins_with("class_name"):
					continue
				else:
					for cname in arg_class_names:
						if cname in line:
							if not script_class_instances.has(script_file_key):
								script_class_instances[script_file_key] = []
							assert(typeof(script_class_instances[script_file_key])\
									== TYPE_ARRAY)
							if not cname  in script_class_instances[script_file_key]:
								script_class_instances[script_file_key].append(cname)
	# console log output, or check inspector
	for sci in script_class_instances:
		print(sci, ": ", script_class_instances[sci])

