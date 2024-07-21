extends Node

class_name SignalUtility

##############################################################################

# SignalUtility is collection of static signal management methods

##############################################################################

# public


# verifies that a connection exists before attempting to connect
# if connection already exists, return true
# if connection does not exist, create it and return true if successful
# if connection does not exist and cannot be created, return false
static func confirm_connection(
		arg_subject_signal: Signal,
		arg_target_method: Callable,
		arg_binds: Array = []) -> bool:
	if arg_subject_signal.is_connected(arg_target_method):
		return true
	else:
		if (arg_subject_signal.connect(arg_target_method.bindv(arg_binds))) == OK:
			return true
		else:
			return false


##############################################################################

# private


