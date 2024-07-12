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
	"GlobalLog": "res://addons/gpf/autoload/global_log.gd",
	"GlobalData": "res://addons/gpf/autoload/global_data.gd",
	"GlobalFunc": "res://addons/gpf/autoload/global_functions.gd",
}

##############################################################################

# setters/getters

##############################################################################

# virts


func _enter_tree():
	for name_key in AUTOLOAD_PATHS:
		add_autoload_singleton(name_key, AUTOLOAD_PATHS[name_key])


func _exit_tree():
	for name_key in AUTOLOAD_PATHS:
		remove_autoload_singleton(name_key)


##############################################################################

# public

##############################################################################

# private

