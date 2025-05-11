@tool
extends EditorPlugin

##############################################################################

#//TODO
# revert project setting modular version - default enable all and add settings
#	to remove non-dependent modules?
# add dependency handling
# solve autoload-on-the-fly issue with GlobalBase extension

##############################################################################

const AUTOLOAD_PATHS := {
	"Log": "res://addons/gpf_core/autoload/global_log.gd",
	"Data": "res://addons/gpf_core/autoload/global_data.gd",
	#"GlobalFunc": "res://addons/gpf/autoload/global_functions.gd",
}

const SETTING_PATH_FORMAT := "addons/prototype_framework/{0}"

# setting name: default value
const SETTINGS := {
	"data path": "data"
}

##############################################################################

# setters/getters

##############################################################################

# virts


func _enter_tree():
	for name_key in AUTOLOAD_PATHS:
		add_autoload_singleton(name_key, AUTOLOAD_PATHS[name_key])
	for setting_key in SETTINGS.keys():
		var default_value = SETTINGS[setting_key]
		ProjectSettings.set_setting(SETTING_PATH_FORMAT.format([setting_key]), default_value)


func _exit_tree():
	for name_key in AUTOLOAD_PATHS:
		remove_autoload_singleton(name_key)
	for setting_key in SETTINGS.keys():
		ProjectSettings.set_setting(SETTING_PATH_FORMAT.format([setting_key]), null)


##############################################################################

# public

##############################################################################

# private
