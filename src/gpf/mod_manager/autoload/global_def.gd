extends Node

#class_name GlobalDef

##############################################################################

# GlobalDef reads DefManagers, stores a record of DefManagers, and acts
#	as an interface to retrieve data from DefManagers.
# GlobalDef loads before GlobalMod and enables DefManager interaction 
#	with GlobalMod

##############################################################################

#//DOCUMENTATION OUT OF DATE AS OF 0.1.4

# GlobalDef creates and stores defManagers.

#//HOW TO ADD YOUR OWN DEFINITON MANAGER
# #1, create a script extending defManager
#	- from res://src/ddat-gpf/mod_manager/classes/class_definition_manager.gd
#
# #2, adjust the 'defmgr_id' property within your
#	new defManager. Unless you know what you are doing, these should be
#	unique. You can change these properties in the file saved to disk
#	(see step 3) or set them in the init() method of your new defMgr.
#
# #3, save your defManager to disk, making sure the .tres file for it
#	is located in the path specified by the DEFMGR_DIRECTORY constant.
#
# #4, optionally shadow the method '_on_mod_load_finished' in your new
#	defManager; this is the location you should add logic for what to
#	actually do with loaded definitions and files once the game is open.
#	Alternatively you can access this data via globalDef.get_def(*args)
#	from any script.
#
# #5, optionally create one or more custom resource-extended classes to
#	act as your definition files within your mod folders. These can be
#	used to expose settings to modders and construct scenes on ready.
#	- make sure modders have access to examples of your .tres files.

# Refer to 'defmgr_dev' within res://src/ddat-gpf/mod_manager/defmgrs/
#	for an example of how to implement a custom defManager (defmgr_dev
#	loads from the 'dev' directory and autoplays .ogg files)

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

signal global_def_setup_complete()
signal all_defmgr_finished()

const DEFMGR_DIRECTORY := "res://def/_defmgrs"

# the def managers active (loaded from defmgr directory)
var def_managers := {}

# all defmgrs, tracking who has completed '_on_mod_load_finished' method
# (if true, method has run)
# {defmgr_id: load state}
var def_manager_load_state := {}
# if all def managers load state is set true in above dict
var are_defmgrs_finished_loading := false

# see _write_testmod_structure
var write_testmod_on_startup := false

# if globalDef has finished its own setup
var setup_complete := false

##############################################################################

# virtual methods


func _ready():
	if GlobalMod.connect("ready", Callable(self, "_on_global_mod_ready")) != OK:
		GlobalLog.error(self, "failed connect GlobalDef->GlobalMod")
	_load_defmgrs()
	_setup_defmgr_signals()
	if write_testmod_on_startup:
		_write_testmod_structure()
	setup_complete = true
	emit_signal("global_def_setup_complete")
	
	# this step helps looking at defmgr data in-editor
	await self.all_defmgr_finished
	var defmgr_value
	for defmgr_key in def_managers.keys():
		defmgr_value = def_managers[defmgr_key]
		if defmgr_value is DefManager:
			var new_defmgr_container = EditorDefManagerContainer.new()
			self.call_deferred("add_child", new_defmgr_container)
			new_defmgr_container.name = defmgr_key
			new_defmgr_container.data = defmgr_value.data
			#//TODO add sub child nodes which store data for each key in data


##############################################################################

# public methods


# if arg_defmgr_id is specified will return the data of every defmgr,
#	otherwise returns data from a specific defmgr
# caution: getting all definitions could be a lot of data
#//TODO add test for new defmgr directory structure and alt for get _raw_data
func get_all_defs(arg_defmgr_id: String = "") -> Dictionary:
	# get data from one defmgr
	if arg_defmgr_id in def_managers.keys():
		var defmgr = def_managers[arg_defmgr_id]
		if defmgr is DefManager:
			return defmgr.data
	
	# get all data
	elif arg_defmgr_id == "":
		var all_data := {}
		for defmgr in def_managers.values():
			if defmgr is DefManager:
				all_data[defmgr.defmgr_id] = []
				for entry in defmgr.data:
					all_data[defmgr.defmgr_id].append(entry)
		return all_data
	
	# catch-all, invalid arg
#	else:
	GlobalLog.error(self, "get_all_defs.arg_defmgr_id invalid")
	return {}


# as get_def but assumes the def_directory_id argument is the same as the
#	arg_defmgr_id argument (i.e. returns base directory or unsorted
#	definitions)
func get_base_def(arg_defmgr_id: String, arg_def_id: String = ""):
	return get_def(arg_defmgr_id, arg_defmgr_id, arg_def_id)


# will return a list of all defs loaded by the associated defmgr under
# the specific definition (file name)
# call with the defManager's defmgr_id property as the first argument
# the second arg is the name of the directory the file was stored in
# the third arg is the file name (without extension)
# will return null if nothing found
func get_def(
		arg_defmgr_id: String,
		arg_def_directory_id: String = "",
		arg_def_id: String = ""):
	arg_def_id = arg_def_id.to_lower()
	var defs_found = null
	var defmgr = _get_def_mgr_by_id(arg_defmgr_id)
	if defmgr == null:
		GlobalLog.warning(self, "cannot find defmgr "+str(arg_defmgr_id))
		return null
	if defmgr is DefManager:
		if arg_def_directory_id == "" and arg_def_id == "":
			defs_found = defmgr.data
		elif arg_def_id == "":
			if defmgr.data.has(arg_def_directory_id):
				defs_found = defmgr.data[arg_def_directory_id]
			else:
				defs_found = null
		elif arg_def_directory_id == "":
			defs_found = defmgr.get_def(defmgr.defmgr_id, arg_def_id)
		else:
			defs_found = defmgr.get_def(arg_def_directory_id, arg_def_id)
	return defs_found


# return null if not found
func get_defmgr(arg_defmgr_id: String) -> DefManager:
	if is_defmgr_loaded(arg_defmgr_id):
		for defmgr in def_managers.values():
			if defmgr is DefManager:
				if defmgr.defmgr_id == arg_defmgr_id:
					return defmgr
	# exit case
	return null


# returns bool true/false if def found
# same arguments as get_def
func has_def(
		arg_defmgr_id: String,
		arg_def_directory_id: String = "",
		arg_def_id: String = "") -> bool:
	return (get_def(arg_defmgr_id, arg_def_directory_id, arg_def_id) != null)


func has_def_directory(
		arg_defmgr_id: String,
		arg_def_directory_id: String) -> bool:
	var defmgr = _get_def_mgr_by_id(arg_defmgr_id)
	if defmgr == null:
		GlobalLog.warning(self, "cannot find defmgr "+str(arg_defmgr_id))
		return false
	else:
		if defmgr is DefManager:
			if defmgr.data.is_empty():
				return false
			else:
				return (defmgr.data.has(arg_def_directory_id))
	# catch-all
	return false


# check whether a defmgr is loaded or not
func is_defmgr_loaded(arg_defmgr_id: String) -> bool:
	for defmgr in def_managers.values():
		if defmgr is DefManager:
			if defmgr.defmgr_id == arg_defmgr_id:
				return true
	# exit case
	return false


##############################################################################

# private methods


# find active defManager by string matching defmgr_id
# if not found will return null
func _get_def_mgr_by_id(arg_def_id: String):
	for defmgr in def_managers.values():
		if defmgr is DefManager:
			if defmgr.defmgr_id == arg_def_id:
				return defmgr
	# catchall
	return null


# populates the def_managers record with all defmgr resources found in
#	the defmgr specified directory, storing them as {defmgr_id (defmgr property): defmgr}
func _load_defmgrs():
	var all_defmgrs = GlobalData.load_resources_in_directory(DEFMGR_DIRECTORY)
	for potential_defmgr in all_defmgrs:
		if potential_defmgr is DefManager:
			def_managers[potential_defmgr.defmgr_id] = potential_defmgr
			def_manager_load_state[potential_defmgr.defmgr_id] = false


# on signal receipt of a defmgr finished loading
# checks if all defmgrs have finished loading their raw_data
func _on_defmgr_finished(arg_defmgr):
	if arg_defmgr is DefManager:
		GlobalLog.debug_info(self, "defmgr {0} is finished".format([arg_defmgr.defmgr_id]))
	# should not be the case when this is called
	if def_manager_load_state.is_empty() and not are_defmgrs_finished_loading:
		return
	if arg_defmgr is DefManager:
		if arg_defmgr.defmgr_id in def_manager_load_state.keys():
			def_manager_load_state[arg_defmgr.defmgr_id] = true
	# will output finished if all defmgrs have finished loading
	var all_finished = true
	for outcome in def_manager_load_state.values():
		if typeof(outcome) == TYPE_BOOL:
			all_finished = (all_finished and outcome)
	if all_finished:
		self.are_defmgrs_finished_loading = true
		emit_signal("all_defmgr_finished")


# sets signals on each DefManager so they can interact with GlobalMod and then
#	inform GlobalDef that they are finished
func _setup_defmgr_signals():
	if def_managers.is_empty():
		self.are_defmgrs_finished_loading = true
	else:
		for def_mgr in def_managers.values():
			if def_mgr is DefManager:
				var err_code = 0
				if GlobalFunc.confirm_connection(GlobalMod, "finished",
						def_mgr, "_on_mod_load_finished") != OK:
					err_code = 1
				if GlobalFunc.confirm_connection(def_mgr, "defmgr_finished",
						self, "_on_defmgr_finished", [def_mgr]) != OK:
					err_code = 2
				if err_code != 0:
					GlobalLog.error(self, "{0} setup fail code {1}".format([
							def_mgr, err_code]))


# perform setup on global mod to pass information it needs to function
func _on_global_mod_ready() -> void:
	if setup_complete != true:
		await self.global_def_setup_complete
	var signal_connection = GlobalFunc.confirm_connection(
			GlobalMod, "load_def", self, "_on_load_def")
	if signal_connection != OK:
		GlobalLog.error(GlobalMod, "GlobalMod and GlobalDef failed to connect")
	# pass defmgr ids for which directories to read
	for defmgr in def_managers.values():
		if defmgr is DefManager:
			GlobalMod.def_mgr_directories.append(defmgr.defmgr_id)
	GlobalMod.start_mod_load()


func _on_load_def(mod_loader: ModLoader):
	for defmgr in def_managers.values():
		if defmgr is DefManager:
#			print("defmgrid check, ", mod_loader.defmgr_id, defmgr.defmgr_id)
			if defmgr.defmgr_id == mod_loader.defmgr_id:
				defmgr.load_def(mod_loader)
			else:
				# elevated log only, all defmgrs try load every modloader so this will error spam
				GlobalLog.error(self, "invalid modloader", true)


# creates a testmod in user directory, if it can't already be found
func _write_testmod_structure():
	var path_to_mods =\
			GlobalData.get_dirpath_user()+"/"+\
			GlobalMod.ROOT_MOD_DIRECTORY_NAME
	var testmodpath = path_to_mods+"/"+"testmod"
	var path_to_about = testmodpath+"/"+GlobalMod.PATH_TO_ABOUT_FILE
	var dirpath_to_about = path_to_about.get_base_dir()
	var dirpath_to_version = testmodpath+"/"+str(GlobalMod.GAME_VERSION)
	var test_about_file = ModAbout.new()
	# check what we're writing
	var version_dir_exists = GlobalData.validate_directory(dirpath_to_version)
	var about_dir_exists = GlobalData.validate_directory(dirpath_to_about)
	var about_file_exists = GlobalData.validate_file(path_to_about)
	
	var is_version_dir_written := false
	var is_about_dir_written := false
	var is_about_file_written := false
	
	if not version_dir_exists:
		is_version_dir_written =\
				(GlobalData.create_directory(dirpath_to_version, true) == OK)
	
	if not about_dir_exists:
		is_about_dir_written =\
				(GlobalData.create_directory(dirpath_to_about, true) == OK)
	
	if not about_file_exists:
		is_about_file_written =\
				(GlobalData.save_resource(
				path_to_about, test_about_file) == OK)
	
	var output_state := false
	output_state = (version_dir_exists or is_version_dir_written) and\
			(about_dir_exists or is_about_dir_written) and\
			(about_file_exists or is_about_file_written)
	if output_state == false:
		GlobalLog.error(self, "write file on write_testmod_structure")




##############################################################################

