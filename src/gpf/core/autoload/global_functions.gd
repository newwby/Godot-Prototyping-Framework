extends GameGlobal

#class_name GlobalFunc

##############################################################################

# GlobalFunctions

#//TODO
# change to globalfunc.gd not globalfunctions
# confirm connection/disconnection need return -> values

##############################################################################

signal node_reparented(node)

# cmdline args are used in multiple methods they are read at runtime instead
#	of at every call
var cmdline_args = {}

##############################################################################

# virtual


func _ready():
	_parse_cmdline_args()


##############################################################################

# public


# ensures a specific signal connection exists between sender and target
# logs warnings if signals are not correct
# returns OK if connection exists or is created
# returns ERR if the connection cannot be found and is not succesfully made
func confirm_connection(
		arg_origin: Object,
		arg_signal_name: String,
		arg_target: Object,
		arg_method_name: String,
		binds: Array = [],
		flags: int = 0
		):
	# validate
	if _confirm_connect_args(arg_origin, arg_signal_name, arg_target, arg_method_name) != OK:
		return ERR_INVALID_PARAMETER
	# run connection, get outcome
	var return_code := ERR_CANT_CONNECT
	if arg_origin.is_connected(arg_signal_name, Callable(arg_target, arg_method_name)):
		return_code = OK
	else:
		return_code =\
				arg_origin.connect(arg_signal_name, Callable(arg_target, arg_method_name).bind(binds), flags)
	
	# return and log
	if return_code != OK:
		GlobalLog.warning(arg_origin,
				"confirm_connection: {0} not connected to {1}.{2}".format(
				[arg_signal_name, arg_target, arg_method_name]))
	return return_code


# ensures a specific signal connection does not exist between sender and target
# logs warnings if signals are not correct
# returns OK if connection exists or is created
# returns ERR if the connection cannot be found and is not succesfully made
func confirm_disconnection(
		arg_origin: Object,
		arg_signal_name: String,
		arg_target: Object,
		arg_method_name: String
		):
	# validate
	if _confirm_connect_args(arg_origin, arg_signal_name, arg_target, arg_method_name) != OK:
		return ERR_INVALID_PARAMETER
	# run disconnection, get outcome
	var return_code:= ERR_ALREADY_EXISTS
	if arg_origin.is_connected(arg_signal_name, Callable(arg_target, arg_method_name)):
		arg_origin.disconnect(arg_signal_name, Callable(arg_target, arg_method_name))
	if (arg_origin.is_connected(arg_signal_name, Callable(arg_target, arg_method_name)) == false):
		return_code = OK
	else:
		return_code = ERR_CANT_RESOLVE
	
	# return and log
	if return_code != OK:
		GlobalLog.warning(arg_origin,
				"confirm_disconnection: {0} not disconnected from {1}.{2}".format(
				[arg_signal_name, arg_target, arg_method_name]))
	return return_code


# DEPRECATED
# (see https://github.com/newwby/ddat-gpf.core/issues/10)
# Use the methods 'confirm_connection' or 'confirm_disconnection' instead
func confirm_signal(
		is_added: bool,
		sender: Node,
		recipient: Node,
		signal_string: String,
		method_string: String
		) -> bool:
	#
	var signal_return_state := false
	var signal_modify_state := OK
	#
	if is_added:
		# on (is_added == true)
		# if signal connection already exists or was successfully added,
		# return true
		if not sender.is_connected(signal_string, Callable(recipient, method_string)):
			signal_modify_state =\
					sender.connect(signal_string, Callable(recipient, method_string))
			# signal didn't exist so must be connected for return state to be valid
			signal_return_state = (signal_modify_state == OK)
		# if already connected under (is_added == true), is valid
		else:
			signal_return_state = true
	#
	elif not is_added:
		# on (is_added == false)
		# if signal connection does not already exist or was successfully
		# removed, return true
		if sender.is_connected(signal_string, Callable(recipient, method_string)):
			sender.disconnect(signal_string, Callable(recipient, method_string))
			# no err code return on disconnect, so assume successful
			signal_return_state = true
		# if not already connected under (is_added == false), is valid
		else:
			signal_return_state = true
		
	return signal_return_state


# converts a String into a Boolean, Integer, Real (Float), or Vector2 variant
#	if the given string is valid of being converted
# types are prioritised in the above order (i.e. if is valid integer it will
#	be converted into integer rather than a float)
# if cannot convert will return the same string
func string_to_type(arg_string: String):
	if arg_string == "True" or arg_string == "true":
		return true
	elif arg_string == "False" or arg_string == "false":
		return false
	elif arg_string.is_valid_int():
		return int(arg_string)
	elif arg_string.is_valid_float():
		return float(arg_string)
	elif arg_string[0] == "(" and arg_string[-1] == ")":
		return string_to_vector(arg_string)
	else:
		return arg_string


func string_to_vector(string := "") -> Vector2:
	if string:
		var new_string: String = string
		new_string.erase(0, 1)
		new_string.erase(new_string.length() - 1, 1)
		var vec_array: Array = new_string.split(", ")
		var vec_x = 0.0
		var vec_y = 0.0
		if typeof(vec_array[0]) == TYPE_STRING:
			if vec_array[0].is_valid_float():
				vec_x = vec_array[0]
		if typeof(vec_array[1]) == TYPE_STRING:
			if vec_array[1].is_valid_float():
				vec_y = vec_array[1]
		return Vector2(vec_x, vec_y)
	# else
	return Vector2.ZERO


# verify if the specific cmdline argument exists in this runtime, and returns
#	the value of the cmdline argument
func get_cmd_arg(arg_key: String):
	# output
	if cmdline_args.has(arg_key):
		return cmdline_args[arg_key]
	else:
		return null


# from a given class name finds every class (including custom classes) that
#	directly or indirectly inherits from that class
# will return an empty poolStringArray if nothing is found
func get_inheritance_from_name(
			arg_class_name: String) -> PackedStringArray:
	# find inbuilt classes
	var output: PackedStringArray = []
	if ClassDB.class_exists(arg_class_name):
		output.append_array(ClassDB.get_inheriters_from_class(arg_class_name))
	# find custom classes
#	var class_sample = instance_from_name(arg_class_name)
#	if class_sample != null:
	# custom_classes is an array of dictionaries
	# each dict corresponds to a single class, with keys as follows
	# base:		string name of class it extends
	# class:	name of class (match to arg_class_name)
	# language:	script language class is written in (i.e. GDScript)
	# path:		local (res://) path to script
	var custom_classes: Array =\
			ProjectSettings.get_setting("_global_script_classes")
	var all_inheritors: PackedStringArray = [arg_class_name]
	if not custom_classes.is_empty():
		var loop_condition := false
		var starting_size = all_inheritors.size()
		# going to loop through the custom class dict-array repeatedly
		#	finding every class that either inherits from the base class
		#	argument, or from a class that inherits from a class that did,
		#	or a descendent of that, etc.
		#	loop breaks when new classes weren't found
		while loop_condition == false:
			starting_size = all_inheritors.size()
			for class_dict in custom_classes:
				assert(class_dict.has("base"))
				if class_dict["base"] in all_inheritors:
					var get_class_name = class_dict["class"]
					assert(typeof(get_class_name) == TYPE_STRING)
					if not get_class_name in all_inheritors:
						all_inheritors.append(get_class_name)
			loop_condition = (starting_size == all_inheritors.size())
	output.append_array(all_inheritors)
	return output


# pass dict and array of keys expected to be in the dict
# returns array of values matching each key
# set arg_silent to true to ignore error logging
func get_values_by_keys(arg_key_array: Array, arg_dict: Dictionary, arg_silent: bool = false) -> Array:
	if arg_key_array.is_empty():
		GlobalLog.error(self, "get_values_by_key error - invalid argument arg_key_array")
	if arg_dict.is_empty():
		GlobalLog.error(self, "get_values_by_key error - invalid argument arg_dict")
		return []
	var returned_value_array := []
	for key in arg_key_array:
		if arg_dict.has(key):
			returned_value_array.append(arg_dict[key])
		elif arg_silent == false:
			GlobalLog.warning(self, "get_values_by_key error - key {0} not found on dict {1}".format([key, arg_dict]))
	return returned_value_array


# returns the first object in the scene tree to match the class of a passed object
#//DEVNOTE: this will only look at top level built-in classes and ignore custom
#	or extended classes
#//TODO add support for custom classes
# can optionally pass required properties (see argument structure for
#	'has_property_value_pairs' method to ensure you get a valid object
# can optionally pass an array of node references (such as a node group as
#	the third argument instead of the default entire tree structure
func get_first_instance_in_tree(arg_class: Object, arg_required_properties := {}, arg_nodes := get_tree_structure()) -> Object:
	if is_instance_valid(arg_class) == false:
		GlobalLog.error(self, "empty comparison class, cannot get_first_instance_in_tree")
		return null
	if arg_nodes.is_empty():
		GlobalLog.error(self, "empty arg_nodes, cannot get_first_instance_in_tree")
		return null
	else:
		for node in arg_nodes:
			if node is Object:
				if node.get_class() == arg_class.get_class():
					if has_property_value_pairs(node, arg_required_properties):
						return node
	# else
	# not finding a matching object is a possibility so this error is not logged
	#	by default; make sure to validate return result outside this method
	# elevate logging permissions (to see this result) if it is returning
	#	null when you do not expect it
	GlobalLog.debug_error(self, "get_first_instance_in_tree exit error 0; "+\
			"either invalid class ({0}) specified, ".format([arg_class])+\
			"or no matching object existed in the tree")
	return null


# return result will be big, do not use this without understanding the impact
func get_tree_structure(arg_node = get_tree().root, arg_all_nodes := []) -> Array:
	if not arg_node in arg_all_nodes:
		arg_all_nodes.append(arg_node)
	for childNode in arg_node.get_children():
		arg_all_nodes = get_tree_structure(childNode, arg_all_nodes)
	return arg_all_nodes


# verify if the specific cmdline argument exists in this runtime, and that
#	the given value matches the cmdline arg value
# values are always read in as string
func has_cmd_arg(arg_key: String) -> bool:
	if cmdline_args.has(arg_key):
		return true
	# else
	return false


# verify if the specific cmdline argument exists in this runtime, and that
#	the given value matches the cmdline arg value
# values are always read in as string
func has_cmd_arg_value(arg_key: String, arg_value: String) -> bool:
	var cmdarg_value = null
	if cmdline_args.has(arg_key):
		cmdarg_value = cmdline_args[arg_key]
		if arg_value == cmdarg_value:
			return true
		print(arg_key, cmdarg_value)
	# else
	return false


func has_property_value_pairs(arg_node: Object, arg_property_value_pairs := {}) -> bool:
	if is_instance_valid(arg_node) == false:
		return false
	if arg_property_value_pairs.is_empty():
		return true
	# else dostuff
	return true # placeholder


# pass a class name and returns an object of that type
# returns null if can't find object
func instance_from_name(arg_class_name: String) -> Object:
	# first check if is inbuilt class
	# (else check custom classes (see below ClassDB block))
	if ClassDB.class_exists(arg_class_name):
		if ClassDB.can_instantiate(arg_class_name):
			return ClassDB.instantiate(arg_class_name)
		else:
			GlobalLog.warning(self, arg_class_name+" is inbuilt but cannot instance")
			return null
	
	# custom_classes is an array of dictionaries
	# each dict corresponds to a single class, with keys as follows
	# base:		string name of class it extends
	# class:	name of class (match to arg_class_name)
	# language:	script language class is written in (i.e. GDScript)
	# path:		local (res://) path to script
	var custom_classes: Array =\
			ProjectSettings.get_setting("_global_script_classes")
	if not custom_classes.is_empty():
		for class_dict in custom_classes:
			if class_dict["class"] == arg_class_name:
				var script_path = class_dict["path"]
				if GlobalData.validate_file(script_path):
					var class_script = load(script_path)
					if class_script is Script:
						if class_script.has_method("new"):
							var class_object = class_script.new()
							return class_object
	# catchall
	return null


# returns true if node is both a valid instance and is inside scene tree
# combines two frequently paired calls into one line
func is_valid_in_tree(arg_node: Node):
	if is_instance_valid(arg_node):
		if arg_node.is_inside_tree():
			return true
	# else
	return false


# as confirm_connection but sets and validates multiple connection pairs
# signal_name: method_name
# cannot handle binds or flags, use confirm_connection for that
func multi_connect(
		arg_origin: Object,
		arg_target: Object,
		arg_signal_method_pairs: Dictionary = {}) -> int:
	if arg_signal_method_pairs.is_empty():
		return ERR_DOES_NOT_EXIST
	# store all outputs
	var output: int = OK
	var end_output: int = OK
	var method_name: String = ""
	for signal_name in arg_signal_method_pairs.keys():
		method_name = arg_signal_method_pairs[signal_name]
		output = confirm_connection(arg_origin, signal_name, arg_target, method_name)
		if output != OK:
			GlobalLog.error(self,
					"[connect] {0} signal: {1} -> {2} method: {3} invalid".format([
					arg_origin, signal_name, arg_target, method_name]))
		end_output = end_output and output
	# if all were OK, this should be OK
	return end_output


# as confirm_disconnection but sets and validates multiple connection pairs
# signal_name: method_name
func multi_disconnect(
		arg_origin: Object,
		arg_target: Object,
		arg_signal_method_pairs: Dictionary = {}):
	if arg_signal_method_pairs.is_empty():
		return ERR_DOES_NOT_EXIST
	# store all outputs
	var output: int = OK
	var end_output: int = OK
	var method_name: String = ""
	for signal_name in arg_signal_method_pairs.keys():
		method_name = arg_signal_method_pairs[signal_name]
		output = confirm_disconnection(arg_origin, signal_name, arg_target, method_name)
		if output != OK:
			GlobalLog.error(self,
					"[disconnect] {0} signal: {1} -> {2} method: {3} invalid".format([
					arg_origin, signal_name, arg_target, method_name]))
		end_output = end_output and output
	# if all were OK, this should be OK
	return end_output


# allows configuring a target object's properties in a single call
func multiset_properties(arg_target: Object, arg_property_dict: Dictionary) -> void:
	if is_instance_valid(arg_target) == false:
		GlobalLog.error(self, "provided invalid target for multiset_properties")
		return
	if arg_property_dict.is_empty():
		return
	for property in arg_property_dict.keys():
		if typeof(property) != TYPE_STRING:
			GlobalLog.warning(self, [property, "invalid type"])
		if property in arg_target:
			# If the given value's type doesn't match no warning is logged.
			arg_target.set(property, arg_property_dict[property])
		else:
			GlobalLog.warning(self, [property, " not found"])


# as multiset_properties but only takes a node in tree as first argument
# if node isn't in tree this method will yield until it is
func multiset_node_on_ready(arg_target: Node, arg_property_dict: Dictionary) -> void:
	if is_instance_valid(arg_target) == false:
		GlobalLog.error(self, "provided invalid target for multiset_node_on_ready")
		return
	if arg_target.is_inside_tree() == false:
		await arg_target.tree_entered
	multiset_properties(arg_target, arg_property_dict)


# method to move a node from beneath one node to another
# if not already inside tree (parent not found) will skip removing step
# will emit signal with node when finished, does not return as return
#	will be delayed with deferred remove/add steps; return signal will
#	include node as value if succesful, or null if not
# [parameters]
# #1, 'arg_target_node' - the node to be moved to a new parent; this node
#	can already have a parent or not even be in the scene tree
# #2, 'arg_new_parent' - the intended destination node to parent
#	arg_target_node beneath
func reparent_node(arg_target_node: Node, arg_new_parent: Node) -> void:
	var reparent_success := false
	# don't pass invalid parameters
	if arg_target_node == null or arg_new_parent == null:
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
			await arg_target_node.tree_entered
			# confirm
			if arg_target_node.is_inside_tree():
				if arg_target_node.get_parent() == arg_new_parent:
					reparent_success = true
	# if succesful exit condition was reached
	if reparent_success:
		emit_signal("node_reparented", arg_target_node)
	else:
		emit_signal("node_reparented", null)


static func sort_ascending(arg_a, arg_b):
	if arg_a[0] < arg_b[0]:
		return true
	return false


static func sort_descending(arg_a, arg_b):
	if arg_a[0] < arg_b[0]:
		return false
	return true


# runs stepify method on both axis of a vector then returns result
func stepify_vec2(arg_vector: Vector2, arg_step: float) -> Vector2:
	var new_x = snapped(arg_vector.x, arg_step)
	var new_y = snapped(arg_vector.y, arg_step)
	return Vector2(new_x, new_y)


##############################################################################

# private


# takes the main arguments from confirm_connection or confirm_disconnection
#	and returns whether they are valid
func _confirm_connect_args(
		arg_origin: Object,
		arg_signal_name: String,
		arg_target: Object,
		arg_method_name: String
		) -> int:
	# log string format is origin."signal" -> target.method()
	var log_string := "{0}.\"{1}\" -> {2}.{3}()".format([
			arg_origin, arg_signal_name, arg_target, arg_method_name])
	
	if is_instance_valid(arg_origin) == false:
		log_string += " | error 1; origin invalid"
		GlobalLog.warning(self, log_string)
		return ERR_INVALID_PARAMETER
	
	if is_instance_valid(arg_target) == false:
		log_string += " | error 2; target invalid"
		GlobalLog.warning(self, log_string)
		return ERR_INVALID_PARAMETER
	
	if not arg_origin.has_signal(arg_signal_name):
		log_string += " | error 3; origin signal invalid"
		GlobalLog.warning(self, log_string)
		return ERR_INVALID_PARAMETER
	
	if not arg_target.has_method(arg_method_name):
		log_string += " | error 4; target method invalid"
		GlobalLog.warning(self, log_string)
		return ERR_INVALID_PARAMETER
	# else
	return OK


# since various methods use these cmdline_args, read them at runtime
func _parse_cmdline_args() -> void:
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			cmdline_args[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			cmdline_args[argument.lstrip("--")] = ""

