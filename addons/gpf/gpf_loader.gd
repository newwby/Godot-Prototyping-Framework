@tool
extends EditorPlugin

# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME_LOGGER = "GlobalLog"
const AUTOLOAD_NAME_DATA = "GlobalData"

const AUTOLOAD_PATH_LOGGER := "res://addons/gpf/autoload/global_log.gd"
const AUTOLOAD_PATH_DATA := "res://addons/gpf/autoload/global_data.gd"


func _enter_tree():
	# The autoload can be a scene or script file.
	add_autoload_singleton(AUTOLOAD_NAME_LOGGER, AUTOLOAD_PATH_LOGGER)
	add_autoload_singleton(AUTOLOAD_NAME_DATA, AUTOLOAD_PATH_DATA)


func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME_LOGGER)
	remove_autoload_singleton(AUTOLOAD_NAME_DATA)
