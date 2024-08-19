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
#func before_each():
#	pass


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
	_validate_test_debug_action_nodes()
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


##############################################################################

# test called private methods


## method to setup test structure
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


## method to set up test structure
func _validate_test_debug_action_nodes() -> void:
	# separated for better information
	#assert_eq(NodeUtility.is_valid_in_tree(test_object), true)
	assert_eq(is_instance_valid(test_object), true)
	assert_eq(test_object.is_inside_tree(), true)
