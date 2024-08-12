extends Node

#class_name GlobalDebug

##############################################################################

## <class_doc>
## GlobalDebug is an autoload that can track DebugActions and DebugValues.

##############################################################################

# var

## Structure is {key : DebugAction, ...}.
var debug_actions = {}
## Structure is {key : DebugValue, ...}.
var debug_values = {}

##############################################################################

# virt

##############################################################################

# public methods


## method adds a new DebugAction to the GlobalDebug tracker, under the debug_actions dict
func add_debug_action(arg_owner: Node, arg_method: String, arg_key, arg_name: String = ""):
	if NodeUtility.is_valid_in_tree(arg_owner):
		if arg_owner.has_method(arg_method):
			var new_debug_action = DebugAction.new(arg_owner, arg_method, arg_key, arg_name)
			# check setup went well
			var setup_correctly = false
			if new_debug_action.is_valid():
				if new_debug_action.is_exiting.connect(_on_debug_element_exit_tree) != OK:
					GlobalLog.error(self, "signal setup error on new DebugAction w/args {0} / {1} / {2} / {3}".\
						format([arg_owner, arg_key, arg_name, arg_method]))
					setup_correctly = true
			if setup_correctly:
				debug_actions[arg_key] = new_debug_action


## method adds a new DebugValue to the GlobalDebug tracker, under the debug_values dict
func add_debug_value(arg_owner: Node, arg_property: String, arg_key, arg_name: String = ""):
	if NodeUtility.is_valid_in_tree(arg_owner):
		if arg_property in arg_owner:
			var new_debug_value = DebugValue.new(arg_owner, arg_property, arg_key, arg_name)
			# check setup went well
			var setup_correctly = false
			if new_debug_value.is_valid():
				if new_debug_value.is_exiting.connect(_on_debug_element_exit_tree) != OK:
					GlobalLog.error(self, "signal setup error on new DebugValue w/args {0} / {1} / {2} / {3}".\
						format([arg_owner, arg_key, arg_name, arg_property]))
					setup_correctly = true
			if setup_correctly:
				debug_actions[arg_key] = new_debug_value


## Method to manually remove a DebugElement from tracking (also frees the associated DebugElement).
## Will return an error code if cannot find the element, or OK otherwise.
func remove_debug_action(arg_key):
	if debug_actions.has(arg_key):
		var get_element = debug_actions[arg_key]
		if get_element is DebugAction:
			get_element.delete()
			debug_actions.erase(arg_key)
			return OK
	# else
	return ERR_CANT_RESOLVE


## Method to manually remove a DebugElement from tracking (also frees the associated DebugElement)
## Will return an error code if cannot find the element, or OK otherwise.
func remove_debug_value(arg_key):
	if debug_values.has(arg_key):
		var get_element = debug_values[arg_key]
		if get_element is DebugValue:
			get_element.delete()
			debug_values.erase(arg_key)
			return OK
	# else
	return ERR_CANT_RESOLVE


##############################################################################

# private methods


## called whenever a DebugElement's owner leaves the tree, removing the DebugElement from being
## tracked by GlobalDebug.
func _on_debug_element_exit_tree(arg_debug_element):
	# remove
	if arg_debug_element is DebugAction:
		if debug_actions.keys().has(arg_debug_element.key):
			debug_actions.erase(arg_debug_element.key)
	# remove
	elif arg_debug_element is DebugValue:
		if debug_values.keys().has(arg_debug_element.key):
			debug_values.erase(arg_debug_element.key)
	else:
		GlobalLog.error(self, "_on_debug_element_exit_tree called w/invalid object: {0}".format([arg_debug_element]))

