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
		arg_subject_signal: Signal,
		arg_target_method: Callable,
		arg_binds: Array = []) -> bool:
	if arg_subject_signal.is_connected(arg_target_method):
		return true
	else:
		if (arg_subject_signal.connect(arg_target_method.bindv(arg_binds))) == OK:
			return true
		else:
			return false


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


