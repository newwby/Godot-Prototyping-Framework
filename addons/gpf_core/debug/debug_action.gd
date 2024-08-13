class_name DebugAction
extends BaseDebugElement

## <class_doc>
## Stores a method from a node in the scene tree under a key name.

##############################################################################

## name of the method to track
var method: String = ""

##############################################################################

# constructor


func _init(arg_owner: Node, arg_method: String, arg_key, arg_name: String = "", arg_category: String = ""):
	super(arg_owner, arg_key, arg_name, arg_category)
	if is_valid:
		if method != "" and owner.has_method(method):
			self.method = arg_method
		else:
			GlobalLog.error(self, "invalid method on new DebugAction: args {0} / {1} / {2} / {3}".\
					format([arg_owner, arg_key, arg_name, arg_method]))


##############################################################################


## calls the tracked method of the owner
func get_action() -> void:
	if is_valid:
		if owner.has_method(method):
			owner.call(method)
		else:
			GlobalLog.error(self, "invalid method on fetching DebugAction: args {0} / {1} / {2} / {3}".\
					format([owner, key, name, method]))
	else:
		_is_invalid()

