@tool
extends EditorPlugin

# for accessing public methods
class_name  GPFManager

##############################################################################

# docs/todo

##############################################################################

const _MODULE_DATA := {
	# GlobalLog
	"Log": {
		"autoload_name": "GlobalLog",
		"autoload_path": "res://addons/gpf/autoload/global_log.gd",
		"autoload_default": true,
		"dependencies": [],
		"property_path": "gpf/autoloads/global_log",
		"property_type": TYPE_BOOL,
		"property_hint": PROPERTY_HINT_NONE,
		"property_hint_string": "",
		"autoload_description": "GlobalLog provides basic logging functionality."
			},
	
	# GlobalData
	"Data": {
		"autoload_name": "GlobalData",
		"autoload_path": "res://addons/gpf/autoload/global_data.gd",
		"autoload_default": true,
		"dependencies": ["Log"],
		"property_path": "gpf/autoloads/global_data",
		"property_type": TYPE_BOOL,
		"property_hint": PROPERTY_HINT_NONE,
		"property_hint_string": "",
		"autoload_description": "GlobalData provides validated methods for saving to and loading from disk."
			},
	
	# GlobalData
	"Function": {
		"autoload_name": "GlobalFunction",
		"autoload_path": "res://addons/gpf/autoload/global_functions.gd",
		"autoload_default": true,
		"dependencies": ["Log", "Data"],
		"property_path": "gpf/autoloads/global_func",
		"property_type": TYPE_BOOL,
		"property_hint": PROPERTY_HINT_NONE,
		"property_hint_string": "",
		"autoload_description": "GlobalFunction contains various misc methods used by GPF modules."
			},
		
	}

# keeps track of whether autoloads are currently active
# this is to prevent updating autoloads on any project settings change
var current_autoload_installs := {}

##############################################################################

# setters/getters

##############################################################################

# virts


func _enter_tree():
	# add signal so can toggle autoloads via project setting options
	ProjectSettings.settings_changed.connect(_update_autoloads)
	_add_settings()


func _exit_tree():
	# remove the signal established on activating plugin
	if ProjectSettings.is_connected("settings_changed", _update_autoloads):
		ProjectSettings.settings_changed.disconnect(_update_autoloads)
	_remove_settings()


##############################################################################

# public


# method to consistently add a basic project setting with propertyinfo
static func add_project_setting(
		arg_path: String,
		arg_value,
		arg_type: Variant.Type,
		arg_hint: PropertyHint,
		arg_hint_string: String = "") -> void:
	ProjectSettings.set_setting(arg_path, arg_value)
	ProjectSettings.set(arg_path, arg_value)
	ProjectSettings.set_initial_value(arg_path, arg_value)
	ProjectSettings.set_as_basic(arg_path, true)
	var property_info = {
		"name": arg_path,
		"type": arg_type,
		"hint": arg_hint,
		"hint_string": arg_hint_string
	}
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.save()


# method to consistently remove a project setting with simplified path structuring
static func delete_project_setting(arg_path: String) -> void:
	ProjectSettings.set_initial_value(arg_path, null)
	ProjectSettings.save()
#
#
## static for getting validated autoload default setting
## should be passed a key _MODULE_DATA
## returns empty array (no dependencies) on invalid exit
#static func get_module_dependencies(arg_key: String) -> Array:
	#if arg_key in _MODULE_DATA:
		#assert(_MODULE_DATA[arg_key].has("dependencies"))
		#var outp_value = _MODULE_DATA[arg_key]["dependencies"]
		#assert(typeof(outp_value) == TYPE_ARRAY)
		#return outp_value
	## error output
	#return []
#
#
## static for getting validated autoload name
## should be passed a key _MODULE_DATA
## returns empty string on invalid exit
#static func get_module_name(arg_key: String) -> String:
	#if arg_key in _MODULE_DATA:
		#assert(_MODULE_DATA[arg_key].has("autoload_name"))
		#var outp_value = _MODULE_DATA[arg_key]["autoload_name"]
		#assert(typeof(outp_value) == TYPE_STRING)
		#return outp_value
	## error output
	#return ""
#
#
## static for getting validated autoload path
## should be passed a key _MODULE_DATA
## returns empty string on invalid exit
#static func get_module_autoload_path(arg_key: String) -> String:
	#if arg_key in _MODULE_DATA:
		#assert(_MODULE_DATA[arg_key].has("autoload_path"))
		#var outp_value = _MODULE_DATA[arg_key]["autoload_path"]
		#assert(typeof(outp_value) == TYPE_STRING)
		#return outp_value
	## error output
	#return ""
#
#
## static for getting validated autoload path
## should be passed a key _MODULE_DATA
## returns empty string on invalid exit
#static func get_module_setting_path(arg_key: String) -> String:
	#if arg_key in _MODULE_DATA:
		#assert(_MODULE_DATA[arg_key].has("property_path"))
		#var outp_value = _MODULE_DATA[arg_key]["property_path"]
		#assert(typeof(outp_value) == TYPE_STRING)
		#return outp_value
	## error output
	#return ""
#

##############################################################################

# private


# pass a key from _MODULE_DATA
# if related project setting equals true, loads the autoload if it is not loaded
# if related project setting equals false, unloads the autoload if it is loaded
# if related project setting is missing, remove the autoload
func _update_autoloads() -> void:
	for module_key in _MODULE_DATA.keys():
		var module_setting_path = _MODULE_DATA[module_key]["property_path"]
		var current_value = ProjectSettings.get_setting(module_setting_path)
		if current_value != current_autoload_installs[module_key]:
			if current_value == true:
				_add_module_autoload(module_key)
			elif current_value == false:
				_remove_module_autoload(module_key)

func _add_module_autoload(arg_module_key: String) -> void:
	var module_autoload_name = _MODULE_DATA[arg_module_key]["autoload_name"]
	if current_autoload_installs[arg_module_key] != true\
	and not ProjectSettings.has_setting("autoload/{0}".format([module_autoload_name])):
		print("outcome 2")
		add_autoload_singleton(
				module_autoload_name,
				_MODULE_DATA[arg_module_key]["autoload_path"])
		current_autoload_installs[arg_module_key] = true
	print("_add_module_autoload -> ", current_autoload_installs)
	
func _remove_module_autoload(arg_module_key: String) -> void:
	var module_autoload_name = _MODULE_DATA[arg_module_key]["autoload_name"]
	if current_autoload_installs[arg_module_key] == true\
	and ProjectSettings.has_setting("autoload/{0}".format([module_autoload_name])):
		print("outcome 1")
		remove_autoload_singleton(module_autoload_name)
		current_autoload_installs[arg_module_key] = false
	print("_remove_module_autoload -> ", current_autoload_installs)


# checks if the project settings already exist in the project; if they do not
#	adds the project settings and then initialises the autoloads based on
#	their 'autoload_default' value.
func _add_settings() -> void:
	var module_setting_path := ""
	for module_key in _MODULE_DATA.keys():
		module_setting_path = _MODULE_DATA[module_key]["property_path"]
		if not ProjectSettings.has_setting(module_key):
			_check_dependencies(module_key)
			add_project_setting(
				module_setting_path,
				_MODULE_DATA[module_key]["autoload_default"],
				_MODULE_DATA[module_key]["property_type"],
				_MODULE_DATA[module_key]["property_hint"],
				_MODULE_DATA[module_key]["property_hint_string"],
			)
		current_autoload_installs[module_key] = ProjectSettings.get_setting(module_setting_path)
	_update_autoloads()


func _remove_settings() -> void:
	var module_setting_path := ""
	for module_key in _MODULE_DATA.keys():
		module_setting_path = _MODULE_DATA[module_key]["property_path"]
		if ProjectSettings.has_setting(module_key):
			delete_project_setting(module_setting_path)
		current_autoload_installs[module_key] = ProjectSettings.get_setting(module_setting_path)
	_update_autoloads()


#//TODO
# enabling any module should automatically enable modules that it depends on
func _check_dependencies(arg_key: String) -> void:
	# invalid keys skip dependency checks
	if arg_key in _MODULE_DATA.keys():
		var dependencies = _MODULE_DATA[arg_key]["dependencies"]
		assert(typeof(dependencies) == TYPE_ARRAY)
		#//TODO add cyclic dependency check?

