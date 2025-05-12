class_name GPFPlugin
extends Object

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

##############################################################################

# public


static func get_data_path_setting() -> String:
	return SETTING_PATH_FORMAT.format(["data path"])


##############################################################################

# private
