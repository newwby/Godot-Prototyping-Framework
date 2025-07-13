class_name GPFPlugin
extends Object

##############################################################################

# Static methods and fixed references utilised by the PluginLoader

##############################################################################

const AUTOLOAD_PATHS := {
	"Log": "res://addons/gpf_core/autoload/global_log.gd",
	"Data": "res://addons/gpf_core/autoload/global_data.gd",
}

const SETTING_PATH_FORMAT := "addons/prototype_framework/{0}"

# setting name: default value
# string: variant
const SETTINGS := {
	"data path": "data"
}

##############################################################################

# setters/getters

##############################################################################

# virts

##############################################################################

# public


static func get_data_path_setting() -> String:
	return SETTING_PATH_FORMAT.format(["data path"])


##############################################################################

# private
