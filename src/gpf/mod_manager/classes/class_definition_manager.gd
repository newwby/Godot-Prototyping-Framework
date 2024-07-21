extends Resource

class_name DefManager

##############################################################################

# Definition Managers hold files returned from ModLoaders, as part of
# the GlobalMod singleton.

# Every subdirectory inside a mod (within the version directory)
# corresponds to a single definition manager.
# ModLoader targets will be registered by file name 

# NOTE: developers see global_def.gd for more information on how to
# support mods and add your own definition managers

##############################################################################

# every defMgr informs globalDef when they've had a chance to do post-load
# tweaks (as part of _on_mod_load_finished)
# when writing your own defMgr make sure the last thing it does is emit this
signal defmgr_finished()

# emitted if a definition is overwritten by another
signal definiton_overwritten(def_directory_name, def_name, def_object)

# file extensions (without preceding .)
const FILE_EXT_IMPORT := "import"
const FILE_EXT_TRES := "tres"
const FILE_EXT_GD := "gd"
const FILE_EXT_GDC := "gdc" # as gd but for compiled scripts
const FILE_EXT_PNG := "png"
const FILE_EXT_OGG := "ogg"

# file extensions this defmgr is prepared to load
@export var can_load_import := true
@export var can_load_tres := true
@export var can_load_gd := true
@export var can_load_png := true
@export var can_load_ogg := true

# whether to assign Definition object def_id properties automatically after loading
@export var automatic_def_id_assignment := true

# directory names should be unique unless you have multiple defManagers
# working in tandem to load resources into objects, e.g. an audioStream
# defManager loading .ogg/.wav files and an audioStreamPlayer defManager
# creating audioStreamPlayer objects with those as its .stream property
@export var defmgr_id := "defmgr"

# if enabled, sets elevated logs to allowed (shows all) on initilisation
var show_debugging_logs := false

var accepted_file_exts: PackedStringArray = []

# whether the defmgr_finished signal has been emitted or not
var is_finished_loading := false

# after loading has completed, all objects from the directory will be loaded
# and available here for external objects to open.
# in extended Defmanagers the objects inside raw data should be handled
# (under _on_mod_load_finished) and added to the data property
# see _store_def for storage structure
var _raw_data := {}

# raw_data after processing in _on_mod_load_finished
# These are easily accessible by the globalDef 'get_def' method.
# objects are the value, key = file name
var data := {}

##############################################################################

# setters and getters

##############################################################################

# virt


func _init():
	_get_accepted_file_exts()
	if show_debugging_logs:
		GlobalLog.elevate_log_permissions(self)


##############################################################################

# public methods


func get_def(arg_def_directory: String, arg_def_id: String):
	if data.has(arg_def_directory):
		if typeof(data[arg_def_directory]) == TYPE_DICTIONARY:
			if data[arg_def_directory].has(arg_def_id):
				# success state
				return data[arg_def_directory][arg_def_id]
	# fail state
	GlobalLog.warning(self, "[{0}][{1}] not found on data".format([
			arg_def_directory, arg_def_id]))
	return null


# pass a file path from a ModLoader
func load_def(arg_mod_loader: ModLoader):
#	print("loading def of mod_loader.defmgr_id {0} on defmgr_id {1}".format([arg_mod_loader.defmgr_id, defmgr_id]))
	var file_path = arg_mod_loader.file_path
#	print("file_path ", file_path)
	if not GlobalData.validate_file(file_path):
		return
	var file_name = file_path.get_file()
	file_name = file_name.trim_suffix(".import")
	file_name = file_name.trim_suffix("."+file_name.get_extension()).to_lower()
	var file_extension = file_path.get_extension().to_lower()
	
	var def_store_key: String
	var is_root = (arg_mod_loader.directory_id == arg_mod_loader.defmgr_id)
	def_store_key = defmgr_id if is_root else arg_mod_loader.directory_id
	
	# elevated log only
	GlobalLog.trace(self, "attempt load at {0}\nloader {1}, key: {2}".format(
			[file_path, file_extension, file_name]), true)
	# pass to load method
#	print("loading extension ", file_extension, " from ", file_path)
	if file_extension in accepted_file_exts:
		match file_extension:
			FILE_EXT_GD:
				# elevated log only
				GlobalLog.info(self, FILE_EXT_GD+" loader: "+str(file_name), true)
				_store_def(def_store_key, file_name,
						_load_def_gd(file_path))
			FILE_EXT_GDC:
				# elevated log only
				GlobalLog.info(self, FILE_EXT_GDC+" loader: "+str(file_name), true)
				_store_def(def_store_key, file_name,
						_load_def_gd(file_path))
			FILE_EXT_IMPORT:
				# elevated log only
				GlobalLog.info(self, FILE_EXT_GD+" loader: "+str(file_name), true)
				_store_def(def_store_key, file_name,
						_load_def_import(file_path))
			FILE_EXT_TRES:
				# elevated log only
				GlobalLog.info(self, FILE_EXT_GD+" loader: "+str(file_name), true)
				_store_def(def_store_key, file_name,
						_load_def_tres(file_path))
			FILE_EXT_OGG:
				# elevated log only
				GlobalLog.info(self, FILE_EXT_GD+" loader: "+str(file_name), true)
				_store_def(def_store_key, file_name,
						_load_def_ogg(file_path))
			FILE_EXT_PNG:
				# elevated log only
				GlobalLog.info(self, FILE_EXT_GD+" loader: "+str(file_name), true)
				_store_def(def_store_key, file_name,
						_load_def_png(file_path))
#	else:
#		print("found invalid extension - ", file_extension)


##############################################################################

# private methods


# get accepted file extensions from bool exports
func _get_accepted_file_exts():
	if can_load_import:
		accepted_file_exts.append(FILE_EXT_IMPORT)
	if can_load_tres:
		accepted_file_exts.append(FILE_EXT_TRES)
	if can_load_gd:
		accepted_file_exts.append(FILE_EXT_GD)
		accepted_file_exts.append(FILE_EXT_GDC)
	if can_load_png:
		accepted_file_exts.append(FILE_EXT_PNG)
	if can_load_ogg:
		accepted_file_exts.append(FILE_EXT_OGG)


#func _get_raw_def(arg_def_directory: String, arg_def_id: String):
#	if _raw_data.has(arg_def_directory):
#		if typeof(_raw_data[arg_def_directory]) == TYPE_DICTIONARY:
#			if _raw_data[arg_def_directory].has(arg_def_id):
#				# success state
#				return _raw_data[arg_def_directory][arg_def_id]
#	# fail state
#	GlobalLog.warning(self, "[{0}][{1}] not found on _raw_data".format([
#			arg_def_directory, arg_def_id]))
#	return null


# load script and return as script;
#	users should create objects from script when they get the definition
# script constructor arguments should specify default arguments (even if
#	null) to prevent invalid or failed loads
func _load_def_gd(arg_file_path: String):
	return GlobalData.load_resource(arg_file_path)

# alt1
#	print("_load_def_gd called on ", arg_file_path)
#	var res_script = load(arg_file_path)
#	if is_instance_valid(res_script):
#		if res_script is Script:
#			if res_script.has_method("new"):
#				return res_script.new()
#	# else
##	var new_script = res_script.new()
#	return res_script

# alt2
#	var script_load = GlobalData.load_resource(arg_file_path)
#	if script_load is Script:
#		if script_load.has_method("new"):
#			return script_load.new()


func _load_def_import(arg_file_path: String):
	var strext = arg_file_path.get_extension()
	# removes .import from file path
	arg_file_path.erase(arg_file_path.find(strext)-1, strext.length()+1)
	return load(arg_file_path)


# stream ogg file from external path
func _load_def_ogg(arg_file_path: String) -> AudioStreamOggVorbis:
	var ogg_file = File.new()
	ogg_file.open(arg_file_path, File.READ)
	var stream_res = AudioStreamOggVorbis.new()
	stream_res.data = ogg_file.get_buffer(ogg_file.get_length())
	ogg_file.close()
	return stream_res


# load png file from external path, creating a texture
func _load_def_png(arg_file_path: String) -> ImageTexture:
#	var img_file = Image.new().load(arg_file_path)
	var file_loader = File.new()
	var image_loader = Image.new()
	# get content
	file_loader.open(arg_file_path, File.READ)
	var file_buffer = file_loader.get_buffer(file_loader.get_length())
	file_loader.close()
	# process content
	if image_loader.load_png_from_buffer(file_buffer) != OK:
		GlobalLog.warning(self, "png file at {0} failed to load".format([
				arg_file_path]))
	image_loader.fix_alpha_edges()
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image_loader)
	return image_texture


# tres files correspond to text definitions
# how text definitons are handled are down to the developer (add logic to
# read the defManager _raw_data property in the '_on_mod_load_finished' method)
func _load_def_tres(arg_file_path: String):
	return GlobalData.load_resource(arg_file_path)


# this method is automatically connected by globalDef to globalMod
# it is called when all ModLoaders have been processed
# shadow this method in extended defManagers
# NOTE: if shadowing either call this parent method at the conclusion of
# your method's logic (via ._on_mod_load_finished)
func _on_mod_load_finished():
	if automatic_def_id_assignment:
		_assign_def_ids()
	# handle signal/state for GlobalDef
	if not is_finished_loading:
		is_finished_loading = true
		emit_signal("defmgr_finished")
		# if no processing is added, make raw data the accessible data 
		if data.is_empty():
			data = _raw_data


func _assign_def_ids() -> void:
	# assign def_id to definition objects
	if _raw_data.is_empty() == false:
		for directory in _raw_data:
			if typeof(_raw_data[directory]) == TYPE_DICTIONARY:
				for sub_directory in _raw_data[directory]:
					if _raw_data[directory][sub_directory] is Definition:
						_raw_data[directory][sub_directory].def_id = "{0}.{1}.{2}".format([defmgr_id, directory, sub_directory])
						GlobalLog.debug_info(self, "auto-assigning {0}.def_id as {1}".format([_raw_data[directory][sub_directory], "{0}.{1}.{2}".format([defmgr_id, directory, sub_directory])]))
			else:
				if _raw_data[directory] is Definition:
					_raw_data[directory].def_id = "{0}.{1}".format([defmgr_id, directory])
					GlobalLog.debug_info(self, "auto-assigning {0}.def_id as {1}".format([_raw_data[directory], "{0}.{1}".format([defmgr_id, directory])]))


# as _store_def method but saves to data instead of _raw_data
# call this in extended DefMgrs as part of _on_mod_load_finished if you only
#	wish to move certain defs to data after validating (e.g. after checking type)
func _save_def(arg_def_directory_key, arg_def_key, arg_def_value) -> void:
	# get top-level dict data
	if not data.has(arg_def_directory_key):
		data[arg_def_directory_key] = {}
	if not typeof(data[arg_def_directory_key]) == TYPE_DICTIONARY:
		GlobalLog.error(self, "_rawdata[{0}] is not dict".format([
				arg_def_directory_key]))
		return
	
	# store nested dict data
	if data[arg_def_directory_key].has(arg_def_key):
		GlobalLog.info(self, "def in defmgr '{0}' overwritten | def:[{1}][{2}]".format([
				defmgr_id, arg_def_directory_key, arg_def_key]))
		GlobalLog.info(self, "old file is {0}, new file is {1}".format([
			data[arg_def_directory_key][arg_def_key], arg_def_value]))
		emit_signal("definiton_overwritten",
				arg_def_directory_key, arg_def_key, arg_def_value)
	# elevated log only
	GlobalLog.info(self, "defmgr \"{3}\" storing data[{1}][{2}]: {0}".\
			format([arg_def_value, arg_def_directory_key, arg_def_key, defmgr_id]), true)
	# store the def
	data[arg_def_directory_key][arg_def_key] = arg_def_value


# definitions are stored in nested dicts where the top-dict key matches
# the lowest level directory in the file path (e.g. "def/enemy/dire_rat/0.png"
# would be stored as {"dire_rat": {"0": resource}"}
# if 
# _store_def overwrites any definition already existing at the location 
func _store_def(arg_def_directory_key, arg_def_key, arg_def_value) -> void:
	# get top-level dict data
	if not _raw_data.has(arg_def_directory_key):
		_raw_data[arg_def_directory_key] = {}
	if not typeof(_raw_data[arg_def_directory_key]) == TYPE_DICTIONARY:
		GlobalLog.error(self, "_rawdata[{0}] is not dict".format([
				arg_def_directory_key]))
		return
	
	# store nested dict data
	if _raw_data[arg_def_directory_key].has(arg_def_key):
		GlobalLog.info(self, "def in defmgr '{0}' overwritten | def:[{1}][{2}]".format([
				defmgr_id, arg_def_directory_key, arg_def_key]))
		GlobalLog.info(self, "old file is {0}, new file is {1}".format([
			_raw_data[arg_def_directory_key][arg_def_key], arg_def_value]))
		emit_signal("definiton_overwritten",
				arg_def_directory_key, arg_def_key, arg_def_value)
	# elevated log only
	GlobalLog.info(self, "defmgr \"{3}\" storing _raw_data[{1}][{2}]: {0}".\
			format([arg_def_value, arg_def_directory_key, arg_def_key, defmgr_id]), true)
	# store the def
	_raw_data[arg_def_directory_key][arg_def_key] = arg_def_value


## saves a loaded definition to the _raw_data property, with the value forced
## to be an array containing the definition
#func _store_def_array(arg_key, arg_value) -> void:
#	if _raw_data.has(arg_key):
#		if typeof(_raw_data[arg_key]) == TYPE_ARRAY:
#			_raw_data[arg_key].append(arg_value)
#	else:
#		_raw_data[arg_key] = [arg_value]

