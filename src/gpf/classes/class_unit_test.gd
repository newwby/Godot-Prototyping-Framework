extends Node

class_name UnitTest

##############################################################################

# Unit tests should be extensions of the node class, named for the class and
# class feature they are testing, e.g. if the test were for the Node class
# and 'add_child' method, a good name would be 'test_node_add_child'.


##############################################################################

@export var test_name := "Undefined Test Name"
# optional flag for adding additional verbose logging
@export var verbose := false

@export var autostart := false
# this must be set for test to run
@export var is_test_readied := false
# if is_test_readied is set false after running test once
@export var test_unreadied_after_iteration := false
# if unreadied will call ready_test method during _test_prepare (start_test)
@export var call_ready_on_start := true
# how many times this test can run
@export var test_iteration_maximum := 1

var test_iteration_total: int = 0

##############################################################################

# virtual methods


func _ready():
	if autostart:
		var _test_result = start_test()


##############################################################################

# public methods


# call on unit test class with an array full of unit tests
# as long as all tests output a bool this will output a bool
static func multitest(arg_tests: Array = []) -> bool:
	var final_outcome := true
	var test_result
	if arg_tests.is_empty():
		GlobalLog.info(null, "no tests provided for multitest")
		return false
	# ready all tests before calling a multitest, or make sure they all
	# have the property 'call_ready_on_start' set true
	for testobj in arg_tests:
		if testobj is Object:
			if testobj.has_method("start_test"):
				test_result = testobj.start_test()
				if typeof(test_result) == TYPE_BOOL:
					GlobalLog.info(testobj, "test result = {0}".format([
						"passed" if (test_result == true) else "failed"]))
					final_outcome = (final_outcome and test_result)
	# separate log with empty line
	print()
	var outcome_string = "multitest result = {0}".format([
		"passed" if (final_outcome == true) else "failed"])
	GlobalLog.info(null, outcome_string.to_upper())
	return final_outcome


# if is_test_readied is false the test will not run, but it can be set to
# default to true for tests that do not require preset properties
func ready_test() -> void:
	is_test_readied = true


# the start_test method is called by the scene running the test (which should
# have the test as a preloaded object)
# if is_test_readied is false, or if test_iteration_total equals/exceeds
# test_iteration_maximum,  nothing will happen
func start_test() -> bool:
	if _test_prepare():
		# console line break before log
		print()
		GlobalLog.info(self, "[Starting Test '{0}']".format([test_name]))
		var test_outcome = _do_test()
		_test_conclude()
		GlobalLog.info(self, "[Outcome for Test '{0}' = {1}!]".format([test_name, str(test_outcome).to_upper()]))
		return test_outcome
	# test fails if not readied
	else:
		# TEST_NOT_READIED
		GlobalLog.warning(self, 49)
		return false


##############################################################################

# private methods


# SHADOW THIS METHOD IN YOUR EXTENDED UNIT TEST CLASS
# this is where you should add your test logic
# it should always return a test argument
func _do_test() -> bool:
	var test_outcome := false
	return test_outcome


func _set_properties(property_register: Dictionary) -> void:
	var property_value = null
	for property_name in property_register.keys():
		property_value = property_register[property_name]
		if typeof(property_name) == TYPE_STRING:
			if self.get(property_name) != null\
			and property_value != null:
				# If the property does not exist or the given value's type
				# doesn't match, nothing will happen.
				self.set(property_name, property_value)


# whether test can run
func _test_prepare() -> bool:
	if call_ready_on_start and not is_test_readied:
		ready_test()
	if not is_test_readied:
		GlobalLog.warning(self, "test could not start")
		return false
	# else
	return true


func _test_conclude():
	test_iteration_total += 1
	if test_unreadied_after_iteration:
		is_test_readied = false

