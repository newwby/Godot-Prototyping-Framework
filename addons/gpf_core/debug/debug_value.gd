class_name DebugValue
extends BaseDebugElement

## <class_doc>
## Reference to the value of a node's property, whilst that node is in the scene tree.
## DebugValues are designed to be displayed on an overlay screen.
## Value can be any type.

##############################################################################

signal position_changed()

enum POSITION {TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT}

## position to orient this DebugValue
var overlay_position: POSITION = POSITION.TOP_LEFT: set = set_overlay_position

## name of the property to track
var property: String = ""

##############################################################################

# constructor


func _init(
		arg_owner: Node,
		arg_property: String,
		arg_key,
		arg_name: String = "",
		arg_category: String = "",
		arg_position := POSITION.TOP_LEFT):
	super(arg_owner, arg_key, arg_name, arg_category)
	if NodeUtility.is_valid_in_tree(arg_owner):
		if arg_property != "" and arg_property in owner:
			self.property = arg_property
			self.overlay_position = arg_position
		else:
			GlobalLog.error(self, "invalid property on new DebugValue: args {0} / {1} / {2} / {3}".\
					format([arg_owner, arg_key, arg_name, arg_property]))

##############################################################################

# setters/getters


func set_overlay_position(arg_new_position: POSITION):
	var old_position = overlay_position
	overlay_position = arg_new_position
	if old_position != arg_new_position:
		emit_signal("position_changed")


##############################################################################


## returns the tracked property of the owner
func get_value():
	if is_valid:
		if property in owner:
			return owner.get(property)
		else:
			GlobalLog.error(self, "invalid property on fetching DebugValue: args {0} / {1} / {2} / {3}".\
					format([owner, key, name, property]))
			_is_invalid()
			return null
	else:
		_is_invalid()
		return null


## DebugActions require a valid reference to a node inside the tree,
## as well as a valid property reference
func is_valid() -> bool:
	var is_in_tree = super()
	var does_property_exist = (property in owner)
	return is_in_tree and does_property_exist

