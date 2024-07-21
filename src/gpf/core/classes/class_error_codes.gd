extends Resource

class_name ErrorCodes

# add your own error codes here
# don't overlap/shadow the global or extended codes, as these will be checked
# first of all (if not in core, check expanded, if not in ext, check user)
# (see get_code() method)
var user := {
	
}

# ddat-gpf codes that build off of the globalScope error codes
var expanded := {
	49 : "TEST_NOT_READIED"
}

# the core error codes - for a string lookup of their name
# missing godot 4.0 error_string method
var core := {
	1: "FAILED",
	2: "ERR_UNAVAILABLE",
	3: "ERR_UNCONFIGURED",
	4: "ERR_UNAUTHORIZED",
	5: "ERR_PARAMETER_RANGE_ERROR",
	6: "ERR_OUT_OF_MEMORY",
	7: "ERR_FILE_NOT_FOUND",
	8: "ERR_FILE_BAD_DRIVE",
	9: "ERR_FILE_BAD_PATH",
	10: "ERR_FILE_NO_PERMISSION",
	11: "ERR_FILE_ALREADY_IN_USE",
	12: "ERR_FILE_CANT_OPEN",
	13: "ERR_FILE_CANT_WRITE",
	14: "ERR_FILE_CANT_READ",
	15: "ERR_FILE_UNRECOGNIZED",
	16: "ERR_FILE_CORRUPT",
	17: "ERR_FILE_MISSING_DEPENDENCIES",
	18: "ERR_FILE_EOF",
	19: "ERR_CANT_OPEN",
	20: "ERR_CANT_CREATE",
	21: "ERR_QUERY_FAILED",
	22: "ERR_ALREADY_IN_USE",
	23: "ERR_LOCKED",
	24: "ERR_TIMEOUT",
	25: "ERR_CANT_CONNECT",
	26: "ERR_CANT_RESOLVE",
	27: "ERR_CONNECTION_ERROR",
	28: "ERR_CANT_ACQUIRE_RESOURCE",
	29: "ERR_CANT_FORK",
	30: "ERR_INVALID_DATA",
	31: "ERR_INVALID_PARAMETER",
	32: "ERR_ALREADY_EXISTS",
	33: "ERR_DOES_NOT_EXIST",
	34: "ERR_DATABASE_CANT_READ",
	35: "ERR_DATABASE_CANT_WRITE",
	36: "ERR_COMPILATION_FAILED",
	37: "ERR_METHOD_NOT_FOUND",
	38: "ERR_LINK_FAILED",
	39: "ERR_SCRIPT_FAILED",
	40: "ERR_CYCLIC_LINK",
	41: "ERR_INVALID_DECLARATION",
	42: "ERR_DUPLICATE_SYMBOL",
	43: "ERR_PARSE_ERROR",
	44: "ERR_BUSY",
	45: "ERR_SKIP",
	46: "ERR_HELP",
	47: "ERR_BUG",
	48: "ERR_PRINTER_ON_FIRE",
}

#############################################################################


# returns a default error string if passed key can't be found in any
# of the error code dictionaries above
func get_error_message(arg_code_key) -> String:
	if arg_code_key in core.keys():
		return str(core[arg_code_key])
	elif arg_code_key in expanded.keys():
		return str(expanded[arg_code_key])
	elif arg_code_key in user.keys():
		return str(user[arg_code_key])
	else:
		return "undefined error"


 # checks whether a value is a key in any of the above dictionaries
func is_key(arg_code_key) -> bool:
	if arg_code_key in core.keys()\
	or arg_code_key in expanded.keys()\
	or arg_code_key in user.keys():
		return true
	else:
		return false

