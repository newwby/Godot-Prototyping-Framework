extends GutTest

# add broad test description here

##############################################################################

# add any #//TODO here

##############################################################################

# test-scoped variants here

signal test_signal(sample_arg)
signal test_signal_2()

var test_scoped_signal_flag_1 = false
var test_scoped_signal_flag_2 = false

##############################################################################

# test meta methods


# alias for prerun_setup
#func before_all():
	#pass


# alias for setup
#func before_each():
	#pass


# alias for postrun_teardown
#func after_all():
	#pass


# alias for teardown
#func after_each():
	#pass


##############################################################################

# tests


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'arg_delta' is the elapsed time since the previous frame.
#func _process(arg_delta):
#	pass


##############################################################################

# test methods should always start with test_


func test_confirm_connection():
	# both blocks
	# assert that the signal wasn't connected
	# validate that confirm connection returns a bool
	# validate that confirm connection works as a connection method
	# validate that it returns true if signal already exists
	# emit the signal (which each set a test scoped flag)
	
	# test block 1
	assert_eq(test_signal.is_connected(_output_test_signal_1), false)
	assert_eq(NodeUtility.confirm_connection(test_signal, _output_test_signal_1), true)
	assert_eq(test_signal.is_connected(_output_test_signal_1), true)
	assert_eq(NodeUtility.confirm_connection(test_signal, _output_test_signal_1), true)
	emit_signal("test_signal", true)
	
	# test block 2
	assert_eq(test_signal.is_connected(_output_test_signal_2), false)
	assert_eq(NodeUtility.confirm_connection(test_signal_2, _output_test_signal_2), true)
	assert_eq(test_signal_2.is_connected(_output_test_signal_2), true)
	emit_signal("test_signal_2")
	
	# then we check that the test scoped flags were corectly set by the signals
	assert_eq(test_scoped_signal_flag_1, true)
	assert_eq(test_scoped_signal_flag_2, true)


##############################################################################

# private test dependent methods

# separate method due to test logic
func _add_to_tree(arg_node: Node) -> void:
	get_tree().root.call_deferred("add_child", arg_node)
	



func _output_test_signal_1(arg_bool) -> void:
	if typeof(arg_bool) == TYPE_BOOL:
		test_scoped_signal_flag_1 = arg_bool


func _output_test_signal_2() -> void:
	test_scoped_signal_flag_2 = true

