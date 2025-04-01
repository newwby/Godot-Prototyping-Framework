extends Node

class_name NodeUtility

##############################################################################

# NodeUtility is collection of static object management methods

##############################################################################

# public


# verifies that a connection exists before attempting to connect
# if connection already exists, return true
# if connection does not exist, create it and return true if successful
# if connection does not exist and cannot be created, return false
static func confirm_connection(
		arg_signal: Signal,
		arg_callable: Callable,
		arg_binds: Array = []) -> bool:
	if arg_signal.is_connected(arg_callable):
		return true
	else:
		if (arg_signal.connect(arg_callable.bindv(arg_binds))) == OK:
			return true
		else:
			return false


# forces a connection not to exist
# if connection does not exist, return true
# if connection exists and is successfully disconnected, return true
# if connection exists but fails to be disconnected, return false
static func confirm_disconnection(
		arg_signal: Signal,
		arg_callable: Callable) -> bool:
	# if connection doesn't exist no further action
	if not arg_signal.is_connected(arg_callable):
		return true
	else:
		arg_signal.disconnect(arg_callable)
		return not arg_signal.is_connected(arg_callable)


# check if node exists/hasn't been deleted, and is inside scene tree
# will return false if not passed an object, if passed a node not inside
#	the scene tree, or if passed an object that has been freed
# will only return true if passed a valid node inside the scene tree
static func is_valid_in_tree(arg_object) -> bool:
	if is_instance_valid(arg_object) == false:
		return false
	else:
		if arg_object is Node:
			return arg_object.is_inside_tree()
		else:
			return false


##############################################################################

# private
