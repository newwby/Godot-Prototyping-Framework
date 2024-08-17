class_name DebugAction
extends BaseDebugElement

## <class_doc>
## Stores a method from a node in the scene tree under a key name.

##############################################################################

#//TODO
# add support for calling with method arguments

##############################################################################

## name of the method to track
var method := Callable()

##############################################################################

# constructor


func _init(arg_owner: Node, arg_method: Callable, arg_key, arg_name: String = "", arg_category: String = ""):
	super(arg_owner, arg_key, arg_name, arg_category)
	if NodeUtility.is_valid_in_tree(arg_owner):
		if arg_method.is_valid():
			if arg_method.get_object() == arg_owner:
				self.method = arg_method
			# not arg_method.get_object() != arg_owner:
			else:
				GlobalLog.error(self, "callable owner != DebugAction owner on new DebugAction: args {0} / {1} / {2} / {3}".\
					format([arg_owner, arg_key, arg_name, arg_method]))
		# not arg_method.is_valid():
		else:
			GlobalLog.error(self, "invalid method on new DebugAction: args {0} / {1} / {2} / {3}".\
					format([arg_owner, arg_key, arg_name, arg_method]))


##############################################################################


## calls the tracked method of the owner
func get_action() -> void:
	if is_valid:
		if method.is_valid():
			method.call()
		else:
			GlobalLog.error(self, "callable invalid on get_action: args {0} / {1} / {2} / {3}".\
				format([owner, key, name, method]))
	else:
		_is_invalid()


## DebugActions require a valid reference to a node inside the tree,
## as well as a valid method callable reference.
func is_valid() -> bool:
	var is_in_tree = super()
	var is_method_set = method.is_valid()
	return is_in_tree and is_method_set

