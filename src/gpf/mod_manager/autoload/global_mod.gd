extends GameGlobal

#class_name GlobalMod

##############################################################################

#//DOCUMENTATION OUT OF DATE AS OF 0.1.4

# GlobalMod handles loading game objects into catalogued registries with
#	the help of several subclasses. Also see GlobalDef and the DefManager
#	class for a full understanding of how mods are created and loaded.

# [ModDef]
#	ModDefs are objects that track what mod folders exist in usr://mods
#	ModDefs read what subdirectories exist within each mod folder and
#	catalogue files found within those subdirectories by creating a ModLoader
#	per file (which records path, file extension, package id, and file name).

# [ModManager]
#	By default no mods are loaded, except for the core directory.
#	Mods can be enabled or disabled by adding them to the modlist.tres,
#	an object of the modManager class which is saved to the user directory.
#	If no modlist.tres exists, no mods are active, and a blank file will
#	be written to the user directory.
#	If a modlist.tres exists, mods that are in the list (are enabled),
#	and were found during the ModDef cataloguing step, will proceed to the
#	mod loading step.

# [ModLoader]
#	ModLoader is an object created for every mod file to be loaded from disk.
#	ModLoaders are keyed to the mod package id and file name - if duplicate
#	keys are found, only the most recent will be tracked (all others will
#	be discarded). Modders can overwrite core content or other mod content
#	by loading their mod later in the mod order.
#	ModLoaders keep track of what

# [Order of Operations]
#	[GlobalDef]
#	1. GlobalDef validates DefManagers from a local directory in res://
#	2. GlobalDef creates DefManager objects and registers them with self
#	[GlobalMod]
#	3. Mod directory is validated
#	4. Mod subdirectories are read and ModDefs are created
#	5. Modlist.tres is validated and loaded, or a blank one is created
#	6. Active mods in modlist.tres are loaded (their modDefs are read to
#		create ModLoader objects) in the order they appear in the list
#		(files from later mods in the list overwrite files from earlier mods)
#	7. ModLoaders are read in the order they were created
#	8. Valid modLoaders (i.e. a modLoader with an associated defManager) pass
#		info about their file to the relevant DefManager
#	9. DefManagers load the file into memory and register it with globalDef

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# emitted by _read_loads_by_def to pass files back to globalDef
signal load_def(mod_loader)

# signal emitted if the active mod list is empty
signal no_mods_found()
# stage based signals, for progress ui elements
# step1
signal mod_defs_built(total_defs)
# step2
signal active_mods_found(total_mods)
signal active_mod_read(mod_id)
# step3
signal mod_loaders_built(mod_id)
signal mod_loaders_failed(failed_loaders)
signal all_mod_loaders_built(total_loaders)
# signal emitted when is finished, whether anything was loaded or not
signal finished()

# this is the current game version and corresponds to the mod folder loaded
const GAME_VERSION := 0.1

const CLASS_VERBOSE_LOGGING := false
const CLASS_NAME := "GlobalMod"

# path to the core definition files; these are loaded like mods, but before
# any mods are loaded (so can be overwritten by mod patches)
# this allows a developer to configure automatic scene/object setup via
# predefined (text-based/.tres) definition files in the same way modders can
const LOCAL_DEFINITION_DIRECTORY := "res://def"

# name of the main mods subdirectory
const ROOT_MOD_DIRECTORY_NAME = "mods"
# name of the modlist file saved in usr://
const MODLIST_FILE_NAME := "modlist.tres"
const PATH_TO_ABOUT_FILE := "/about/about.tres"

# complete path of mod directory (built from user path)
var path_to_mod_directory := ""
# the list of active mods
var modlist: ModLoadList

# which directories to read (passed from globalDef before globalMod starts)
var def_mgr_directories := []

# record of all modDef objects tracking which mods exist and where
var all_mod_defs := []
# record of loaders that failed setup, so they can be inspected or freed
var failed_loaders := []
# value = validated (active) modLoader, key = modLoader.loader_id
var mod_loader_register := {}

# has mod_load run before or not
var mod_load_complete := false

##############################################################################

# virtual methods


func _ready():
	# re-enable logging permission for current testing (parent class disables)
	GlobalLog.change_log_permissions(self, true)
	# set path for all other users
	path_to_mod_directory =\
			GlobalData.get_dirpath_user()+ROOT_MOD_DIRECTORY_NAME
	_validate_base_mod_directory()


##############################################################################

# public methods


# pares down the modDef list to get only the mods specified by the modlist
# as active/enabled mods
func get_active_mods() -> Array:
	var all_active_mods := []
	for mod_definition in all_mod_defs:
		if mod_definition is ModDef:
			if is_mod_active(mod_definition):
				all_active_mods.append(mod_definition)
	emit_signal("active_mods_found", all_active_mods.size())
	return all_active_mods



## PLACEHOLDER, returns directory names for each active definitionManagers
#func get_def_mgr_directories() -> Array:
#	for defmgr in GlobalDef.def_managers.values():
#		if defmgr is DefManager:
#			def_mgr_directories.append(defmgr.defmgr_id)
##	GlobalLog.trace(self, def_mgr_directories)
#	return def_mgr_directories


# method checks whether a mod (the package_id specified in the about file
# of the mod's modDef) is in the active mods list
# will return false if modlist has not been set correctly
# [params]
# #1, arg_mod_definition - the modDef to check against the modlist
func is_mod_active(arg_mod_definition: ModDef) -> bool:
	if modlist != null:
		if arg_mod_definition.package_id in modlist.get_active_mods():
			return true
	# else
	return false


func start_mod_load():
	if mod_load_complete:
		return
	# find modDefinitions
	_create_local_def()
	_read_mod_directories()
	# catalogue mod contents
#	_get_local_loaders()
	_validate_modlist()
	_get_loaders_from_active_mods()
	# load mod contents by defManager
	_read_loaders_by_def()
	mod_load_complete = true
	emit_signal("finished")


# returns whether the add mod/remove mod operation was succesful
# will write the modlist back to disk if any change went ahead
# [params]
# #1, arg_mod_definition - the modDef to add to/remove from the modlist
# #2, arg_add_mod - if true, 
func update_modlist(
		arg_mod_definition: ModDef,
		arg_add_mod: bool = true) -> int:
	var mod_id = arg_mod_definition.package_id
	var modlist_changed := false
	var outcome := ERR_BUG
	# add mod to modlist
	if arg_add_mod:
		if mod_id in modlist.active_mods:
			outcome = ERR_ALREADY_EXISTS
		else:
			modlist.active_mods.append(mod_id)
			if mod_id in modlist.active_mods:
				modlist_changed = true
				outcome = OK
			else:
				outcome = ERR_DATABASE_CANT_WRITE
	# remove mod from modlist
	else:
		if not mod_id in modlist.active_mods:
			outcome = ERR_DOES_NOT_EXIST
		else:
			modlist.active_mods.erase(mod_id)
			if not mod_id in modlist.active_mods:
				modlist_changed = true
				outcome = OK
			else:
				outcome = ERR_DATABASE_CANT_WRITE
	# only write changes if something happened
	if modlist_changed:
		_write_modlist(modlist)
	# exit statement
	return outcome


##############################################################################

# private methods


# creates a default modAbout and modDef for the core game files
func _create_local_def():
	var core_mod_about = ModAbout.new()
	core_mod_about.mod_name = "core"
	core_mod_about.package_id = "core"
	core_mod_about.author = ProjectSettings.get("application/config/name")
	core_mod_about.game_version = GAME_VERSION
	core_mod_about.description = "Core mod files"
	all_mod_defs.append(
			ModDef.new(LOCAL_DEFINITION_DIRECTORY, core_mod_about))


# creates modDefs for every mod found inside a directory
# called on the local definiton path (LOCAL_DEFINITION_DIRECTORY) and
# user definitions path (path_to_mod_directory)
# [params]
# 1, 'arg_directory_names', call globalData.get_directory_names on top level
#	directory
func _create_mod_defs(arg_directory_names: Array):
	var path_to_dir := "/"
	var full_path_to_file := ""
	# catalogue mod directories
	for directory in arg_directory_names:
		if typeof(directory) != TYPE_STRING:
			return
		path_to_dir = path_to_mod_directory+"/"+directory
		full_path_to_file = path_to_dir+PATH_TO_ABOUT_FILE
		# if about.tres file can be found, is at least a valid modDef
		var mod_about_file = null
		if GlobalData.validate_file(full_path_to_file):
			mod_about_file = GlobalData.load_resource(full_path_to_file)
			if mod_about_file is ModAbout:
				all_mod_defs.append(ModDef.new(path_to_dir, mod_about_file))


# fin, write description
# calls the method _get_loaders_from_moddef
func _get_loaders_from_active_mods():
	var active_mods: Array = get_active_mods()
	if active_mods.is_empty():
		return
	var list_of_mod_loaders := []
	# read the modDefs that are in the modlist
	for mod_definition in active_mods:
		if mod_definition is ModDef:
			emit_signal("active_mod_read", mod_definition.package_id)
			# local files are not packaged under a version directory
			if mod_definition.package_id in modlist.MANDATORY_MODS:
				list_of_mod_loaders =\
						_get_loaders_from_moddef(mod_definition, true)
			else:
				# get all the loaders from this particular mod
				list_of_mod_loaders = _get_loaders_from_moddef(mod_definition)
			# add all the loaders to the 
			for mod_loader in list_of_mod_loaders:
				if mod_loader is ModLoader:
					#//NOTE: are dictionaries keys order sensitive?
					mod_loader_register[mod_loader.loader_id] = mod_loader
	# pass total loaders
	emit_signal("all_mod_loaders_built", mod_loader_register.size())


# creates ModLoaders for every file within the mod, identifying and
# cataloguing the file to return it in a list back to the method
# '_get_loaders_from_active_mods' where the mod_loader_register is updated
# [params]
# #1, arg_mod_definition - the modDef to create loaders for
# #2, arg_ignore_version - whether mods have versioned subdirectories
#	# e.g.
	# top level folder of the mod should be named for the version the mod
	# files support
	# i.e. if the game version is 1.0, then the folder structure would go
	# -> mod folder
	#	-> about
	#	-> 1.0 <- versioned subdirectory
	#		-> [mod content here]
func _get_loaders_from_moddef(
		arg_mod_definition: ModDef,
		arg_ignore_version: bool = false
		) -> Array:
	var moddef_loaders := []
	var read_version_directory: String =\
			arg_mod_definition.base_directory_path
	if arg_ignore_version == false:
		read_version_directory += ("/"+str(GAME_VERSION))
	
	# next need to go through every def_mgr approved directory (within
	# the version directory) to find files to create modLoaders for
	var full_directory_read_path := ""
	var files_in_directory := []
	var new_loader: ModLoader
	if not def_mgr_directories.is_empty():
		for directory_key in def_mgr_directories:
			full_directory_read_path =\
					read_version_directory+"/"+str(directory_key)
	#		GlobalLog.trace(self, full_directory_read_path)
			#check paths
			if not GlobalData.validate_directory(full_directory_read_path):
	#			GlobalLog.trace(self, str(full_directory_read_path)+" NOT found")
				continue
	#		else:
	#			GlobalLog.trace(self, str(full_directory_read_path)+" found")
			
			# need to get all file paths recursively
			var all_file_paths := [full_directory_read_path]
	#		GlobalLog.trace(self, "all_file_paths: "+str(all_file_paths))
			all_file_paths.append_array(
					GlobalData.get_dir_paths(full_directory_read_path, true))
			for file_path in all_file_paths:
				files_in_directory.append_array(
						GlobalData.get_file_paths(file_path))
			
	#		GlobalLog.trace(self, "files_in_directory "+str(files_in_directory))
			
			# original non-recursive
	#		files_in_directory =\
	#				GlobalData.get_file_paths(full_directory_read_path)
			
	#		GlobalLog.trace(self, files_in_directory)
			# create loaders
			for mod_file_path in files_in_directory:
	#			GlobalLog.trace(self, "loader path: "+str(mod_file_path))
				# no arg_package_id_override (4th arg) if is not patch
				new_loader = ModLoader.new(\
						arg_mod_definition, mod_file_path, directory_key)
#				print(arg_mod_definition.base_directory_path)
#				if directory_key
				if new_loader.loader_valid:
	#				GlobalLog.trace(self, str(mod_file_path)+" loaded")
					moddef_loaders.append(new_loader)
				else:
	#				GlobalLog.warning(self, str(mod_file_path)+" failed to load")
					failed_loaders.append(new_loader)
	# exit
	if not moddef_loaders.is_empty():
		emit_signal("mod_loaders_built", arg_mod_definition.package_id)
	# announce if any loaders failed setup, along with the loaders themselves
	emit_signal("mod_loaders_failed", failed_loaders)
	return moddef_loaders


# method iterates through loaders and loads the file they point toward if
# a defManager who shares defmgr_id with the loader (i.e. is for the same
# directory)
func _read_loaders_by_def():
	pass
	for loader in mod_loader_register.values():
		if loader is ModLoader:
			if loader.is_loaded:
				continue
			else:
				emit_signal("load_def", loader)


# method to scan subdirectories within the usr://mods directory and create
# modDef objects for each valid mod (minimum req = it has an 'about' folder
# and an 'about.tres' (ModAbout object saved as text resource) within)
func _read_mod_directories():
	var mod_directory_names =\
			GlobalData.get_directory_names(path_to_mod_directory)
	_create_mod_defs(mod_directory_names)
	# check how many mods were found
	emit_signal("mod_defs_built", all_mod_defs.size())


# method to find base mod directory, creating it if it doesn't exist
func _validate_base_mod_directory():
	# first off, create the mod directory if it doesn't exist
	if not GlobalData.validate_directory(path_to_mod_directory):
		if GlobalData.create_directory(path_to_mod_directory) != OK:
			GlobalDebug.log_error(CLASS_NAME, "_ready", "failed write mod dir")


# method to load the active mod list (modLoadList) for globalMod
func _validate_modlist():
	var path_to_modlist := GlobalData.get_dirpath_user()+MODLIST_FILE_NAME
#	GlobalLog.trace(self, "path_to_modlist is "+str(path_to_modlist))
	# user directory is always valid no need to validate directory
	# if modlist not found, create it
	if not GlobalData.validate_file(path_to_modlist):
		GlobalLog.info(self, "attempting to write new modlist")
		_write_modlist(ModLoadList.new())
	#
	modlist = GlobalData.load_resource(path_to_modlist, ModLoadList)
	if modlist == null:
		GlobalLog.error(self,
				"cannot load list @ super.modlist({0})".format([modlist]))
	if modlist is ModLoadList:
		if modlist.active_mods.is_empty():
			emit_signal("no_mods_found")


# saves a  modLoadList to disk if one isn't found by _validate_modlist
# [params]
# #1, arg_modlist - the modlist to write to disk
func _write_modlist(arg_modlist: ModLoadList):
	# bugfix for escaped file path
	var modlist_path := GlobalData.get_dirpath_user()+"/"+MODLIST_FILE_NAME
	GlobalLog.info(self, "attempting to write modlist at "+str(modlist_path))
	var return_err =\
			GlobalData.save_resource(
			modlist_path,
			arg_modlist)
	if return_err != OK:
		GlobalLog.error(self,
				"ERR {e} on saving new modlist".format({"e": return_err}))

