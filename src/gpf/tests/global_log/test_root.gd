extends Node

#class_name Name

##############################################################################

# Simple test calls for GlobalLog to verify everything sends to console expectedly

##############################################################################

#05. signals
#06. enums
#07. constants
#
#08. exported variables
#09. public variables
#10. private variables
#11. onready variables

##############################################################################

# setters/getters

##############################################################################

# virts


# Called when the node enters the scene tree for the first time.
func _ready():
	_test_print_to_console()
	_test_log_count()
	_test_log_registration()
	_test_print_elevated()
	_test_print_to_console_critical()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################

# public

##############################################################################

# private


func _test_log_count() -> void:
	# separate test in console
	print()
	var test_log_string := "testing log counting"
	GlobalLog.info(self, test_log_string)
	var initial_log_count := GlobalLog.total_log_calls
	GlobalLog.info(self, test_log_string)
	var updated_log_count := GlobalLog.total_log_calls
	assert(updated_log_count == (initial_log_count + 1))
	print("log count test successful")


func _test_log_registration() -> void:
	# separate test in console
	print()
	var test_log_string := "testing log registration"
	GlobalLog.info(self, test_log_string)
	if GlobalLog.log_register.has(self):
		var log_register_entry = GlobalLog.log_register[self]
		if typeof(log_register_entry) == TYPE_ARRAY:
			print("time for log register entry should be close to '{0}'".format([Time.get_ticks_msec()]))
			print("code for log register entry should be '{0}'".format(["INFO"]))
			print("output for log register entry should be '{0}'".format([test_log_string]))
			print("most recent log register entry = {0}".format([log_register_entry[-1]]))


func _test_print_to_console() -> void:
	# separate test in console
	print()
	var test_log_string_info := "this is a test log for console only"
	var test_log_string_debugger := "this is a test log for debugger and console"
	print("attempting INFO log with string: '{0}'".format([test_log_string_info]))
	GlobalLog.info(self, test_log_string_info)
	print("attempting INFO log with error code 0: 'OK'")
	GlobalLog.info(self, 0)
	print("attempting WARNING log with string: '{0}'; this should raise a debugger warning".\
			format([test_log_string_debugger]))
	GlobalLog.warning(self, test_log_string_debugger)
	print("attempting ERROR log with string: '{0}'; this should raise a debugger error".\
			format([test_log_string_debugger]))
	GlobalLog.error(self, test_log_string_debugger)


func _test_print_elevated() -> void:
	# separate test in console
	print()
	var test_log_default_allowed := "this log should be visible"
	var test_log_default_banned := "this log should NOT be visible"
	var test_log_elevated_no_permission := "this elevated log should NOT be visible"
	var test_log_elevated_with_permission := "this elevated log should be visible"
	print("# default log test on default permissions; the next log should have the message '{0}'".format([test_log_default_allowed]))
	GlobalLog.info(self, test_log_default_allowed)
	print("# default log test on banned permissions; the next log should not be visible")
	GlobalLog.set_permission_disabled(self)
	GlobalLog.info(self, test_log_default_banned)
	print("# default log test after reset to default permissions; the next log should have the message '{0}'".format([test_log_default_allowed]))
	GlobalLog.set_permission_default(self)
	GlobalLog.info(self, test_log_default_allowed)
	print("# elevated log test on default permissions log test; the next log should not be visible")
	GlobalLog.debug_info(self, test_log_elevated_no_permission)
	print("# elevated log test on eleavted permissions log test; the next log should have the message '{0}'".format([test_log_elevated_with_permission]))
	GlobalLog.set_permission_elevated(self)
	GlobalLog.debug_info(self, test_log_elevated_with_permission)


func _test_print_to_console_critical() -> void:
	# separate test in console
	print()
	var test_log_string := "this is a test log which will crash the game"
	print("attempting CRITICAL log with string: '{0}'; expected crash imminent".format([test_log_string]))
	GlobalLog.critical(self, test_log_string)
	

