@tool
extends EditorPlugin

##############################################################################

#//TODO
# revert project setting modular version - default enable all and add settings
#	to remove non-dependent modules?
# add dependency handling
# solve autoload-on-the-fly issue with GlobalBase extension

##############################################################################

# var

const DATABASE_SCENE = preload("res://addons/gpf_core/scenes/data_panel.tscn")

var plugin_panel_instance

##############################################################################

# setters/getters

##############################################################################

# virts


func _enter_tree():
	# initialise singletons & project settings
	for name_key in GPFPlugin.AUTOLOAD_PATHS:
		add_autoload_singleton(name_key, GPFPlugin.AUTOLOAD_PATHS[name_key])
	for setting_key in GPFPlugin.SETTINGS.keys():
		var default_value = GPFPlugin.SETTINGS[setting_key]
		ProjectSettings.set_setting(GPFPlugin.SETTING_PATH_FORMAT.format([setting_key]), default_value)
	
	# create local directories for the plugin
	_verify_local_data_directory()
	# add the plugin database editor tab
	_add_plugin_panel()


func _exit_tree():
	# remove singletons and project settings
	for name_key in GPFPlugin.AUTOLOAD_PATHS:
		remove_autoload_singleton(name_key)
	for setting_key in GPFPlugin.SETTINGS.keys():
		ProjectSettings.set_setting(GPFPlugin.SETTING_PATH_FORMAT.format([setting_key]), null)
	
	# remove the plugin database editor tab
	_remove_plugin_panel()


func _add_plugin_panel():
	plugin_panel_instance = DATABASE_SCENE.instantiate()
	# Add the main panel to the editor's main viewport and hide it initially.
	EditorInterface.get_editor_main_screen().add_child(plugin_panel_instance)
	_make_visible(false)


func _disable_plugin():
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


func _remove_plugin_panel():
	if plugin_panel_instance:
		plugin_panel_instance.queue_free()


##############################################################################

# public


static func get_data_path_setting() -> String:
	return GPFPlugin.SETTING_PATH_FORMAT.format(GPFPlugin.SETTINGS["data path"])


##############################################################################

# private


# if running in editor, and local directories don't exist, create them
func _verify_local_data_directory() -> void:
	var data_directory := ProjectSettings.get_setting(GPFPlugin.get_data_path_setting())
	var local_path = "res://{0}".format([data_directory])
	var local_dir = DirAccess.open(local_path)
	if not local_dir:
		DirAccess.make_dir_recursive_absolute(local_path)
	var schema_path := "{0}/{1}".format([local_path, "_schema"])
	var schema_dir = DirAccess.open(schema_path)
	if not schema_dir:
		DirAccess.make_dir_recursive_absolute(schema_path)
