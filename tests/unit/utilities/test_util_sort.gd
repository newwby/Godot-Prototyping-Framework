extends GutTest

# add broad test description here

##############################################################################

# add any #//TODO here

##############################################################################

# test-scoped variants here

var enable_test_debug_prints := false

##############################################################################

# test meta methods


# alias for prerun_setup
#func before_all():
#	pass


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


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'arg_delta' is the elapsed time since the previous frame.
#func _process(arg_delta):
#	pass


##############################################################################

# test methods should always start with test_


func test_sort_ascending():
	var input_test_data = [
		[1, "Apple"],
		[4, "Pear"],
		[2, "Grape"],
		]
	var expected_output_data = [
		[1, "Apple"],
		[2, "Grape"],
		[4, "Pear"],
		]
	input_test_data.sort_custom(SortUtility.sort_ascending)
	assert(input_test_data.size() == expected_output_data.size())
	for idx in range(input_test_data.size()):
		assert_eq(input_test_data[idx][1], expected_output_data[idx][1])
		# debugging print statement
		if enable_test_debug_prints:
			print("output test_sort_ascending | index {0} | {1} {2} {3}".\
					format([idx,
					input_test_data[idx][1],
					"==" if input_test_data[idx][1] == expected_output_data[idx][1] else "!=",
					expected_output_data[idx][1]]))


func test_sort_descending():
	var input_test_data = [
		[1, "Apple"],
		[4, "Pear"],
		[2, "Grape"],
		]
	var expected_output_data = [
		[4, "Pear"],
		[2, "Grape"],
		[1, "Apple"],
		]
	input_test_data.sort_custom(SortUtility.sort_descending)
	assert(input_test_data.size() == expected_output_data.size())
	for idx in range(input_test_data.size()):
		assert_eq(input_test_data[idx][1], expected_output_data[idx][1])
		# debugging print statement
		if enable_test_debug_prints:
			print("output test_sort_descending | index {0} | {1} {2} {3}".\
					format([idx,
					input_test_data[idx][1],
					"==" if input_test_data[idx][1] == expected_output_data[idx][1] else "!=",
					expected_output_data[idx][1]]))


#static func sort_ascending(a, b):
	#if a[0] < b[0]:
		#return true
	#return false
#
#
#static func sort_descending(a, b):
	#if a[0] > b[0]:
		#return true
	#return false
