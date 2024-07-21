extends Node

class_name ArrayUtility

##############################################################################

# ArrayUtility is collection of static array management methods

##############################################################################

# public


static func sort_ascending(a, b):
	if a[0] < b[0]:
		return true
	return false


static func sort_descending(a, b):
	if a[0] > b[0]:
		return true
	return false


##############################################################################

# private


