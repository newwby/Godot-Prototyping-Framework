extends GutTest

## <class_doc>
##

##############################################################################

# add any #//TODO here

##############################################################################

# test-scoped variants here

var test_object = MockDebugNode.new()
## extra test objects exist to make sure the retrieved test object for
## test_debug_action is the correct one
var test_object_false_1 = MockDebugNode.new()
var test_object_false_2 = MockDebugNode.new()

##############################################################################

# test meta methods


# alias for prerun_setup
func before_all():
	get_tree().root.add_child(test_object)
	get_tree().root.add_child(test_object_false_1)
	get_tree().root.add_child(test_object_false_2)


# alias for setup
func before_each():
	_validate_test_debug_nodes()
	GlobalDebug.clear_all_debug_elements()


# alias for postrun_teardown
#func after_all():
#	pass


# alias for teardown
#func after_each():
#	pass


##############################################################################

# tests


## tests the debug_actions record is being updated
## tests it can be retrieved
func test_fetch_debug_action() -> void:
	_add_test_debug_actions()
	
	var fetch_action = GlobalDebug.get_debug_action("key_test_debug_action")
	if fetch_action == null:
		fail_test("could not fetch DebugAction")
		return
	
	assert_eq(fetch_action is DebugAction, true)
	assert_eq(fetch_action.owner == test_object, true)
	#assert_eq(fetch_action.method == test_method, true)
	if fetch_action is DebugAction:
		fetch_action.get_action()


## tests the debug_actions record is being updated
## tests it can be retrieved
func test_fetch_debug_value() -> void:
	_add_test_debug_values()
	
	#//TODO move scope of these expected values and keys
	### IS NOT ASSIGNING TO DEBUG_VALUES
	var fetch_action_1 = GlobalDebug.get_debug_value("key_test_object_property_1")
	var fetch_action_2 = GlobalDebug.get_debug_value("key_test_object_property_2")
	if fetch_action_1 == null:
		fail_test("could not fetch DebugValue for key: key_test_object_property_1")
		return
	if fetch_action_2 == null:
		fail_test("could not fetch DebugValue for key: key_test_object_property_2")
		return
	
	assert_eq(fetch_action_1 is DebugValue, true)
	assert_eq(fetch_action_2 is DebugValue, true)
	assert_eq(fetch_action_1.owner == test_object, true)
	assert_eq(fetch_action_2.owner == test_object, true)
	# check against expected values
	#//TODO move scope of these expected values and keys
	if fetch_action_1 is DebugValue:
		assert_eq(fetch_action_1.get_value(), 42.0)
	if fetch_action_2 is DebugValue:
		assert_eq(fetch_action_2.get_value(), "hello world!")


##############################################################################

# test called private methods


## method to setup test structure for DebugAction tests
func _add_test_debug_actions() -> void:
	var test_method_1 = test_object.placeholder_debug_method
	var test_method_2 = test_object_false_1.placeholder_debug_method
	var test_method_3 = test_object_false_2.placeholder_debug_method
	assert_eq(GlobalDebug.debug_actions.size(), 0)
	## adds multiple DebugAction objects to make sure we're returning the right one (test_object under key_test_debug_action)
	## assert test after each for successful add
	GlobalDebug.add_debug_action(test_object_false_1, test_method_2, "key_test_false_debug_action")
	assert_eq(GlobalDebug.debug_actions.size(), 1)
	GlobalDebug.add_debug_action(test_object, test_method_1, "key_test_debug_action")
	assert_eq(GlobalDebug.debug_actions.size(), 2)
	GlobalDebug.add_debug_action(test_object, test_method_1, "key_test_debug_action_duplicate")
	assert_eq(GlobalDebug.debug_actions.size(), 3)
	GlobalDebug.add_debug_action(test_object_false_2, test_method_3, "key_test_false_debug_action_no2")
	assert_eq(GlobalDebug.debug_actions.size(), 4)


## method to setup test structure for DebugValue tests
func _add_test_debug_values() -> void:
	var test_property_1_name = "placeholder_value_1"
	var test_property_1_expected_value = 42.0
	var test_property_2_name = "placeholder_value_2"
	var test_property_2_expected_value = "hello world!"
	assert_eq(GlobalDebug.debug_values.size(), 0)
	## adds multiple DebugAction objects to make sure we're returning the right one (test_object under key_test_debug_action)
	## assert test after each for successful add
	#(arg_owner: Node, arg_property: String, arg_key, arg_name: String = "", arg_category: String = ""):
	GlobalDebug.add_debug_value(test_object, test_property_1_name, "key_test_object_property_1")
	assert_eq(GlobalDebug.debug_values.size(), 1)
	GlobalDebug.add_debug_value(test_object, test_property_2_name, "key_test_object_property_2")
	assert_eq(GlobalDebug.debug_values.size(), 2)


## method to set up test structure
func _validate_test_debug_nodes() -> void:
	# separated for better information
	#assert_eq(NodeUtility.is_valid_in_tree(test_object), true)
	assert_eq(is_instance_valid(test_object), true)
	assert_eq(test_object.is_inside_tree(), true)


## just tests the debug_actions record is being updated
#func test_debug_action_registered() -> void:

