extends Node

class_name SortUtility

##############################################################################

# SortUtility is collection of static array sorting methods

##############################################################################

# public


static func sort_ascending(arg_a, arg_b):
	"""sort_ascending returns a list of :class:`bluepy.blte.Service` objects representing
	the services offered by the device. This will perform Bluetooth service
	discovery if this has not already been done; otherwise it will return a
	cached list of services immediately..

	:param uuids: A list of string service UUIDs to be discovered,
		defaults to None
	:type uuids: list, optional
	:return: A list of the discovered :class:`bluepy.blte.Service` objects,
		which match the provided ``uuids``
	:rtype: list On Python 3.x, this returns a dictionary view object,
		not a list
	"""
	if arg_a[0] < arg_b[0]:
		return true
	return false


static func sort_descending(arg_a, arg_b):
	"""sort_descending returns a list of :class:`bluepy.blte.Service` objects representing
	the services offered by the device. This will perform Bluetooth service
	discovery if this has not already been done; otherwise it will return a
	cached list of services immediately..

	:param uuids: A list of string service UUIDs to be discovered,
		defaults to None
	:type uuids: list, optional
	:return: A list of the discovered :class:`bluepy.blte.Service` objects,
		which match the provided ``uuids``
	:rtype: list On Python 3.x, this returns a dictionary view object,
		not a list
	"""
	if arg_a[0] > arg_b[0]:
		return true
	return false


##############################################################################

# private


