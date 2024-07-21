extends Node

#class_name Name

##############################################################################

##############################################################################

@onready var test_conditional_and: UnitTest = $TestConditionalAnd
@onready var test_conditional_or: UnitTest = $TestConditionalOr

##############################################################################

# virt


# Called when the node enters the scene tree for the first time.
func _ready():
	var all_tests_outcome := true
	var test_outcome_1 := true
	var test_outcome_2 := true
	test_outcome_1 = test_conditional_and.start_test()
	test_outcome_2 = test_conditional_or.start_test()
	all_tests_outcome = (all_tests_outcome and test_outcome_1)
	all_tests_outcome = (all_tests_outcome and test_outcome_2)
	GlobalLog.info(self, "\n### Conditionals Unit Tests {0} ###".\
			format(["FAILED" if (all_tests_outcome == false) else "PASSED"]))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################

# public

##############################################################################

# private

