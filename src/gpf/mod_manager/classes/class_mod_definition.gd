extends Resource

class_name ModDef

##############################################################################

# a ModDefinition object is a record of where a mod folder exists
# A ModDefinition object requires a valid modAbout file but otherwise does
#	not require anything else to be present in the mod folder

##############################################################################

var about: ModAbout
var base_directory_path := ""
var package_id := ""

##############################################################################

# virtual methods

func _init(
		arg_path_to_dir: String,
		arg_about_file: ModAbout):
	self.base_directory_path = arg_path_to_dir
	self.about = arg_about_file
	self.package_id = arg_about_file.package_id


##############################################################################

# public methods


#func example_method():
#	pass


##############################################################################

# private methods


#func example_method():
#	pass

