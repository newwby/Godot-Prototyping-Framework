extends Node

#class_name GlobalDebug

##############################################################################

## <class_doc>
## GlobalDebug is an autoload that can track DebugElement objects, specifically
## DebugActions and DebugValues. This exists to be extended into a debugging display
## or control scene, functional examples of which are included with the GPF plugin.
##
## DebugElements are stored under keys, which must be unique within Action or Value scope,
## i.e. a DebugAction and a DebugValue may share a key, but two DebugActions or two
## DebugValues may not share a key. It is best practice to avoid sharing keys altogether however.

##############################################################################

#//TODO
# add get-by-category functions for debug actions/values

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
func add_debug_action(arg_owner: Node, arg_method: Callable, arg_key, arg_name: String = "", arg_category: String = ""):
	if NodeUtility.is_valid_in_tree(arg_owner):
		var new_debug_action = DebugAction.new(arg_owner, arg_method, arg_key, arg_name, arg_category)
		# check setup went well
		var setup_correctly = false
		if new_debug_action.is_valid():
			if new_debug_action.is_exiting.connect(_on_debug_element_exit_tree) == OK:
				setup_correctly = true
			else:
				GlobalLog.error(self, "signal setup error on new DebugAction w/args {0} / {1} / {2} / {3}".\
					format([arg_owner, arg_key, arg_name, arg_method]))
		if setup_correctly:
			debug_actions[arg_key] = new_debug_action


## method adds a new DebugValue to the GlobalDebug tracker, under the debug_values dict
func add_debug_value(arg_owner: Node, arg_property: String, arg_key, arg_name: String = "", arg_category: String = ""):
	if NodeUtility.is_valid_in_tree(arg_owner):
		if arg_property in arg_owner:
			var new_debug_value = DebugValue.new(arg_owner, arg_property, arg_key, arg_name, arg_category)
			# check setup went well
			var setup_correctly = false
			if new_debug_value.is_valid():
				if new_debug_value.is_exiting.connect(_on_debug_element_exit_tree) == OK:
					setup_correctly = true
				else:
					GlobalLog.error(self, "signal setup error on new DebugValue w/args {0} / {1} / {2} / {3}".\
						format([arg_owner, arg_key, arg_name, arg_property]))
			else:
				print("not valid")
			if setup_correctly:
				debug_values[arg_key] = new_debug_value
				return
	# else
	print("invalid setup")


## Method to return the DebugAction associated with the given key.
## Returns null if the key is invalid.
func get_debug_action(arg_key) -> DebugAction:
	if debug_actions.has(arg_key):
		var fetched_action = debug_actions[arg_key]
		if fetched_action is DebugAction:
			return fetched_action
	# else
	return null


## Method to return the DebugAction associated with the given key.
## Returns null if the key is invalid.
func get_debug_value(arg_key) -> DebugValue:
	if debug_values.has(arg_key):
		var fetched_value = debug_values[arg_key]
		if fetched_value is DebugValue:
			return fetched_value
	# else
	return null


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

