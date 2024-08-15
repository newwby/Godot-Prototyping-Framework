extends GutTest

## <class_doc>
##

##############################################################################

# add any #//TODO here

##############################################################################

# test-scoped variants here

var test_object = MockDebugNode.new()

##############################################################################

# test meta methods


# alias for prerun_setup
func before_all():
	get_tree().root.add_child(test_object)


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


## just tests the debug_actions record is being updated
func test_debug_action_registered() -> void:
	var test_method = test_object.placeholder_debug_method
	assert_eq(GlobalDebug.debug_actions.size(), 0)
	# this fails setup test due to this script not actually being in the scene tree
	# try adding a fake test class (stub) with the method
	
	# separated for better information
	#assert_eq(NodeUtility.is_valid_in_tree(test_object), true)
	assert_eq(is_instance_valid(test_object), true)
	assert_eq(test_object.is_inside_tree(), true)
	
	GlobalDebug.add_debug_action(test_object, test_method, "key_test_debug_action")
	assert_eq(GlobalDebug.debug_actions.size(), 1)
	var fetch_action = GlobalDebug.get_debug_action("key_test_debug_action")
	if fetch_action == null:
		fail_test("could not fetch DebugAction")
		return
	
	assert_eq(fetch_action is DebugAction, true)
	assert_eq(fetch_action.owner == test_object, true)
	assert_eq(fetch_action.method == test_method, true)
	if fetch_action is DebugAction:
		fetch_action.get_action()
