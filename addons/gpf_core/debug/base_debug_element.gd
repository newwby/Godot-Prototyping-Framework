class_name BaseDebugElement
extends RefCounted

##############################################################################

## <class_doc>
## This is a base class and should not be used.
## See DebugCommand and DebugValue extended classes for functionality.
## Each DebugElement is tracked by GlobalDebug after being created and can be
## called from GlobalDebug by the key name.
## If the DebugElement's owner node exits the scene tree, it will no longer
## be tracked and cannot be fetched.

##############################################################################

## Signal emitted when DebugElement owner exits the tree.
## Tells GlobalDebug to stop tracking this DebugElement
signal is_exiting(arg_self)

## Owner is the scene-tree node that the DebugElement relates to.
var owner: Node
## Key must be exclusive with other DebugElements.
## If two DebugElements 
## This is used to 
var key
## Name is the display to be shown on an debug menu or overlay screen
## This can be different from key, but if it is left blank, the key will be used instead.
var name: String = "": get = get_name
## Category allows grouping of DebugElement objects within menus,
## e.g. positioning related overlay elements together, or nesting debug command
## buttons underneath a group button (hiding commands until the button is pressed).
var category: String = ""

##############################################################################

# constructor


func _init(arg_owner: Node, arg_key, arg_name: String = "", arg_category: String = ""):
	if NodeUtility.is_valid_in_tree(arg_owner):
		if arg_owner.tree_exiting.connect(_is_invalid) != OK:
			GlobalLog.error(self, "invalid signal on new DebugElement: args {0} / {1} / {2}".\
					format([arg_owner, arg_key, arg_name]))
		else:
			self.owner = arg_owner
			self.key = arg_key
			self.name = arg_name
			self.category = arg_category
	else:
		GlobalLog.error(self, "invalid owner on new DebugElement: args {0} / {1} / {2}".\
				format([arg_owner, arg_key, arg_name]))
		self.free()


##############################################################################

# setters/getters


func get_name() -> String:
	if name != "":
		return name
	else:
		return str(key)


##############################################################################

# public methods


## Call this method to manually remove a DebugElement
func delete() -> void:
	_is_invalid()


## Debug elements require a valid reference to a node inside the tree.
func is_valid() -> bool:
	return NodeUtility.is_valid_in_tree(owner)


##############################################################################

# private methods


func _is_invalid():
	emit_signal("is_exiting", self)

