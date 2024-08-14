extends GutTest

## <class_doc>
##

##############################################################################

# add any #//TODO here

##############################################################################

# test-scoped variants here

##############################################################################

# tests


## just tests the debug_actions record is being updated
func test_debug_action_registered() -> void:
	assert_eq(GlobalDebug.debug_actions.size(), 0)
	GlobalDebug.add_debug_action(self, "_placeholder_debug_element_action", "test_debug_action")
	assert_eq(GlobalDebug.debug_actions.size(), 1)


##############################################################################

# test-dependent private method


## placeholder for adding DebugAction during test_debug_action_registered 
func _placeholder_debug_element_action() -> void:
	pass

