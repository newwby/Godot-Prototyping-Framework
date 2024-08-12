class_name DebugValue
extends BaseDebugElement

## <class_doc>
## Reference to the value of a node's property, whilst that node is in the scene tree.
## DebugValues are designed to be displayed on an overlay screen.
## Value can be any type.

##############################################################################

## name of the property to track
var property: String = ""

##############################################################################

# constructor


func _init(arg_owner: Node, arg_property: String, arg_key, arg_name: String = ""):
	super(arg_owner, arg_key, arg_name)
	if is_valid:
		if property != "" and property in owner:
			self.property = arg_property
		else:
			GlobalLog.error(self, "invalid property on new DebugValue: args {0} / {1} / {2} / {3}".\
					format([arg_owner, arg_key, arg_name, arg_property]))


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

