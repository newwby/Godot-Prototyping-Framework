@tool
extends EditorPlugin

##############################################################################

#//TODO
# revert project setting modular version - default enable all and add settings
#	to remove non-dependent modules?
# add dependency handling
# solve autoload-on-the-fly issue with GlobalBase extension

##############################################################################

const DEPENDENCIES := [
	"autoload/GlobalLog",
]

const AUTOLOAD_PATHS := {
	#"GlobalMod": "add path here",
}

##############################################################################

# setters/getters

##############################################################################

# virts


func _enter_tree():
	if _verify_dependencies():
		print("successful load")
	else:
		print("dependency not met")


func _exit_tree():
	pass


##############################################################################

# public

##############################################################################

# private


func _verify_dependencies() -> bool:
	for dependent_autoload_path in DEPENDENCIES:
		if ProjectSettings.has_setting(dependent_autoload_path) == false:
			return false
	# else
	return true

