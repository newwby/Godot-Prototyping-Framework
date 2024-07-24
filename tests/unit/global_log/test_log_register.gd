extends GutTest

# This test sends an info log message then checks the log register to confirm
#	whether the log message was accurately stored

##############################################################################

#//TODO update with parameterised tests

##############################################################################

var log_register_tickstamp := 0
var test_log_string := "testing log registration"
#//TODO update for non-info log testing or add tests for other log testing
var test_log_code := "INFO"

##############################################################################

# test meta methods


# send test log and disable log output behaviour to minimise console spam
func before_all():
	GlobalLog.allow_log_output = false
	log_register_tickstamp = Time.get_ticks_msec()
	GlobalLog.info(self, test_log_string)


# re-enable log output behaviour afterwards
func after_all():
	GlobalLog.allow_log_output = true


##############################################################################


# tests


func test_log_register_entry_key_exists() -> void:
	assert_has(GlobalLog.log_register, self)


# test_value key equals a key from GlobalLog._store_log
func test_log_register_entry_time() -> void:
	var test_value = _get_log_register_entry("time")
	assert_eq(test_value, log_register_tickstamp)


# test_value key equals a key from GlobalLog._store_log
func test_log_register_entry_code() -> void:
	var test_value = _get_log_register_entry("code")
	assert_eq(test_value, test_log_code)


# test_value key equals a key from GlobalLog._store_log
func test_log_register_entry_output() -> void:
	var test_value = _get_log_register_entry("output")
	assert_eq(test_value, test_log_string)


# dry test parameter fetching
func _get_log_register_entry(arg_key: String):
	if GlobalLog.log_register.has(self):
		var log_register_entry = GlobalLog.log_register[self]
		if typeof(log_register_entry) == TYPE_ARRAY:
			var most_recent_entry = log_register_entry[-1]
			if typeof(most_recent_entry) == TYPE_DICTIONARY:
				if most_recent_entry.has(arg_key):
					return most_recent_entry[arg_key]
	# else
	return null

