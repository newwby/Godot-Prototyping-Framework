extends Node

class_name SortUtility

##############################################################################

# SortUtility is collection of static array sorting methods

##############################################################################

# public


static func sort_ascending(arg_a, arg_b):
	if arg_a[0] < arg_b[0]:
		return true
	return false


static func sort_descending(arg_a, arg_b):
	if arg_a[0] > arg_b[0]:
		return true
	return false


##############################################################################

# private


