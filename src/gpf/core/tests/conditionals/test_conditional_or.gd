extends UnitTest

#class_name Name

##############################################################################

##############################################################################

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

##############################################################################

# virt


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################

# public

##############################################################################

# private


func _do_test():
	# test after applying every value from test_condition_apirs
	# these are the expected outcomes at every step (each index applies to
	#	one condition pair and is tested against after that pair is added/removed)
	var test_structure = {
		ConditionalOr.new(true): [true, true, false, true, true, true], # test_subject_0
		ConditionalOr.new(false): [true, false, false, false, true, true], # test_subject_1
		ConditionalOr.new(true, true): [true, true, true, true, true, true], # test_subject_2 (includes base value)
		ConditionalOr.new(false, true): [true, false, false, false, true, true], # test_subject_3 (includes base value)
		}
	# It should be noted that Conditionals ignore their base value by default
	#	if any value is present
		
	# conditions to apply to conditionals above
	# if condition_key ends with '_add' the condition_key is added as a condition
	# if condition_key ends with '_remove' the condition_key is removed as a condition
	var test_condition_pairs := {
		"test_key_1_add": true,
		"test_key_1_remove": true,
		"test_key_2_add": false,
		"test_key_2_remove": false,
		"test_key_3_add": true,
		"test_key_4_add": true,
	}
	
	var modified_condition_key := ""
	var condition_value
	var test_index := 0
	var test_subject_index := 0
	var all_test_outcomes := []
	var test_step_outcome
	var expected_test_outcome
	var test_step_result := true
	var overall_test_outcome := true
	# tests run on every conditional in test_structure
	for test_conditional in test_structure.keys():
		if not test_conditional is ConditionalOr\
		or typeof(test_structure[test_conditional]) != TYPE_ARRAY:
			GlobalLog.trace(self, "test setup error on test for ConditionalOr")
			continue
		else:
			all_test_outcomes = test_structure[test_conditional]
			var default_evaluate = test_conditional.evaluate()
			if verbose:
				print("\n# starting test loop; initial evaluate {0} on default value {1}".\
						format([default_evaluate, test_conditional.default_outcome]))
			test_index = 0
			
			# run tests
			for condition_key in test_condition_pairs:
				if typeof(condition_key) == TYPE_STRING:
					modified_condition_key = condition_key
					condition_value = test_condition_pairs[condition_key]
					expected_test_outcome = all_test_outcomes[test_index]
					# add condition
					if modified_condition_key.ends_with("_add"):
						modified_condition_key = modified_condition_key.trim_suffix("_add")
						test_conditional.add(modified_condition_key, condition_value)
					# remove condition
					elif modified_condition_key.ends_with("_remove"):
						modified_condition_key = modified_condition_key.trim_suffix("_remove")
						test_conditional.remove(modified_condition_key)
				
				# evaluate test step
				test_step_outcome = test_conditional.evaluate()
				test_step_result = (test_step_outcome == expected_test_outcome)
				if test_step_result == false:
					print("!!! subject {0} at test step {1} expected result '{2}' but got '{3}".\
							format([test_subject_index, test_index, expected_test_outcome, test_step_outcome]))
					print("current conditions are: {0}".format([test_conditional.get_all_conditions()]))
					print("default value is {0}".format([test_conditional.default_outcome]))
				elif verbose:
					print("subject {0} / test step {1} / successful (result {2})".\
							format([test_subject_index, test_index, expected_test_outcome]))
				overall_test_outcome = (overall_test_outcome and test_step_result)
				
				# increment for getting results
				test_index += 1
		# increment for referencing the test subject
		test_subject_index += 1
	
	return overall_test_outcome

