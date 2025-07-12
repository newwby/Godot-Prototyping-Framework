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


func _exit_tree():
	for name_key in GPFPlugin.AUTOLOAD_PATHS:
		remove_autoload_singleton(name_key)
	for setting_key in GPFPlugin.SETTINGS.keys():
		ProjectSettings.set_setting(GPFPlugin.SETTING_PATH_FORMAT.format([setting_key]), null)


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
