extends Resource

class_name ModLoader

##############################################################################

#	File paths are used to load resources.
var file_path := ""
#	Package IDs and File names are used as keys for finding each file.
var loader_id := ""
var package_id := ""
var file_name := ""
#	Extensions are used to define how resources are loaded.
var file_extension := ""
# name of the directory the loader loads from
var directory_id := ""
# DefinitionManager directories inform who to pass this loader to
# (this should be exclusive to a particular definitionManager)
var defmgr_id := ""
# if modLoader was setup correctly
var loader_valid := false
# skip loader if already loaded
var is_loaded := false

##############################################################################

# virt

# establish a modLoader by passing a ModDef
func _init(
		arg_parent_def: ModDef,
		arg_file_path: String,
		arg_defmgr_id: String,
		arg_package_id_override: String = ""):
	self.defmgr_id = arg_defmgr_id
	# arguments must be valid objects of their type to validate the loader
	if arg_parent_def.about != null\
	and defmgr_id in arg_file_path:
		# for patches can force change the loader package_id
		if arg_package_id_override == "":
			self.package_id = arg_parent_def.about.package_id
		else:
			self.package_id = arg_package_id_override
		# other properties formed from file path
		if GlobalData.validate_file(arg_file_path):
			self.file_path = arg_file_path
			var file_path_split = file_path.split("/")
			self.directory_id = file_path_split[-2]
			self.file_name = file_path_split[-1]
			self.file_extension = file_name.get_extension()
			self.file_name = file_name.get_basename()
			self.loader_id = _get_loader_id(file_path, defmgr_id)
	# all properties must be set to validate the loader
	if file_path != ""\
	and defmgr_id != ""\
	and loader_id != ""\
	and package_id != ""\
	and directory_id != ""\
	and file_name != ""\
	and file_extension != "":
		loader_valid = true


##############################################################################

# public methods


#func example_method():
#	pass


##############################################################################

# private methods


# loader id is a unique identifying string for files within a mod
func _get_loader_id(
		arg_file_path: String,
		arg_defmgr_id: String) -> String:
	var new_loader_id = ""
	# getting loader id
	var defmgr_id_startpos =\
			arg_file_path.find(arg_defmgr_id)+arg_defmgr_id.length()
	var filedirstr = arg_file_path.substr(defmgr_id_startpos)
	# get_basename applied twice to handle .ext.import extensions
	filedirstr = filedirstr.get_basename().get_basename()
	new_loader_id = package_id+filedirstr.replace("/", ".")
	return new_loader_id

