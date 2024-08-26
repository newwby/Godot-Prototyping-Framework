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


## TODO ADD TESTING;
## Method to move a node from one parent to another
static func reparent_node(arg_target_node: Node, arg_new_parent: Node) -> void:
	# don't pass invalid parameters
	if not is_instance_valid(arg_target_node)\
	or not is_instance_valid(arg_new_parent):
		GlobalLog.error(null, "reparent_node error 0 w/args {0} & {1}".\
				format([arg_target_node, arg_new_parent]))
		return
		# update for non-void return
#		return ERR_INVALID_PARAMETER
	# remove from initial parent, get target node out of SceneTree
	if arg_target_node.is_inside_tree():
		var old_parent_node = arg_target_node.get_parent()
		if old_parent_node != null:
			old_parent_node.call_deferred("remove_child", arg_target_node)
			await arg_target_node.tree_exited
	# add to new parent
	if not arg_target_node.is_inside_tree():
		if arg_new_parent.is_inside_tree():
			arg_new_parent.call_deferred("add_child", arg_target_node)
			#await arg_target_node.tree_entered
#			# confirm
			#if arg_target_node.is_inside_tree():
				#if arg_target_node.get_parent() == arg_new_parent:
					#reparent_success = true


##############################################################################

# private


