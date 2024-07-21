extends Resource

class_name ModLoadList

##############################################################################

# ModManager
# By default no mods are loaded, except for the core directory.
# Mods can be enabled or disabled by adding them to the modlist.tres,
# an object of the modManager class which is saved to the user directory.
# If no modlist.tres exists, no mods are active, and a blank file will
# be written to the user directory.
# If a modlist.tres exists, mods that are in the list (are enabled),
# and were found during the ModDef cataloguing step, will proceed to the
# mod loading step.

# This is a class rather than a property so it can be saved to disk
# without saving the entire mod autolaod to disk.

#//TODO
#	rewrite as .ini?

##############################################################################

# if the active_mods property is ever empty it defaults to this value
#const DEFAULT_ACTIVE_MODS := ["core"]

# mods (core files) that should always be read
const MANDATORY_MODS := ["core"]

# the list of package ids (look at the about property of the relevant
# modDef object, which should be a modAbout object)
@export var active_mods := ["core"]

##############################################################################

# public


func get_active_mods() -> Array:
	return active_mods+MANDATORY_MODS


#//TODO add mod package_id validation against globalMod.mod_def_register
#func get_mod_list():
#	if _active_mods.empty():
#		return DEFAULT_ACTIVE_MODS
#	else:
#		return _active_mods




##############################################################################

