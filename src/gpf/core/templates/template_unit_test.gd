extends UnitTest

#class_name UnitTestName

##############################################################################

# specific test properties

##############################################################################

# public methods


# add any logic that needs to run before test here
# by default this method is called by start_test() before _do_test()
func ready_test() -> void:
	# at all branch ends make sure is_test_readied is set true or false
	# by default a test will not run if is_test_readied == false
	is_test_readied = true


##############################################################################

# private methods


# add your test logic here, just make sure it returns test outcome as bool
func _do_test() -> bool:
	var test_outcome := false
	return test_outcome


#func _private_test_method():
#	pass

