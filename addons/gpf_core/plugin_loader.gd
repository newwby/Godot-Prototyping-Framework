@tool
extends EditorPlugin

##############################################################################

# Core module for the Godot Prototyping Frameworks
# Includes
#	- Logging Manager
#	- Data Manager
# Planned
#	- Debugging Manager

##############################################################################

# var

const AUTOLOAD_PATHS := {
	"Log": "res://addons/gpf_core/autoload/global_log.gd",
	"Data": "res://addons/gpf_core/autoload/global_data.gd",
}

const DATABASE_SCENE = preload("uid://d4d1ix211l0fe")

const SETTING_PATH_FORMAT := "addons/prototype_framework/{0}"

# setting name: default value
# string: variant
#const SETTINGS := {
	#"data path": "data"
#}

var plugin_panel_instance

##############################################################################

# setters/getters

##############################################################################

# virts


func _disable_plugin():
	_remove_plugin_panel()


# order of operations very important
func _enter_tree():
	_add_settings()
	_verify_local_data_directory()
	_add_autoloads()
	_add_plugin_panel()


func _exit_tree():
	_remove_settings()
	_remove_autoloads()
	_remove_plugin_panel()


# show display name for plugin tab
func _get_plugin_name():
	return "Database"


func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return EditorInterface.get_editor_theme().get_icon("Object", "EditorIcons")


func _has_main_screen():
	return true


func _make_visible(visible):
	if plugin_panel_instance:
		plugin_panel_instance.visible = visible


##############################################################################

# public

##############################################################################

# private


func _add_autoloads() -> void:
	for name_key in AUTOLOAD_PATHS:
		add_autoload_singleton(name_key, AUTOLOAD_PATHS[name_key])


func _add_plugin_panel():
	plugin_panel_instance = DATABASE_SCENE.instantiate()
	# Add the main panel to the editor's main viewport and hide it initially.
	EditorInterface.get_editor_main_screen().add_child(plugin_panel_instance)
	_make_visible(false)


func _add_settings() -> void:
	pass
	# custom settings temporarily disabled as none present
	#for setting_key in SETTINGS.keys():
		#var default_value = SETTINGS[setting_key]
		#ProjectSettings.set_setting(SETTING_PATH_FORMAT.format([setting_key]), default_value)


func _remove_autoloads() -> void:
	# remove singletons and project settings
	for name_key in AUTOLOAD_PATHS:
		remove_autoload_singleton(name_key)


func _remove_plugin_panel():
	if plugin_panel_instance:
		plugin_panel_instance.queue_free()


func _remove_settings() -> void:
	pass
	# custom settings temporarily disabled as none present
	#for setting_key in SETTINGS.keys():
		#ProjectSettings.set_setting(SETTING_PATH_FORMAT.format([setting_key]), null)


# if running in editor, and local directories don't exist, create them
func _verify_local_data_directory() -> void:
	var local_path = "res://{0}".format(["data"])
	var local_dir = DirAccess.open(local_path)
	if not local_dir:
		DirAccess.make_dir_recursive_absolute(local_path)
	var schema_path := "{0}/{1}".format([local_path, "_schema"])
	var schema_dir = DirAccess.open(schema_path)
	if not schema_dir:
		DirAccess.make_dir_recursive_absolute(schema_path)
