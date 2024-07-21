extends Node

class_name ObjectUtility

##############################################################################

# ObjectUtility is collection of static object management methods

##############################################################################

# public


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


