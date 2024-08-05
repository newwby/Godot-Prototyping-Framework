extends Node
## A brief description of the class's role and functionality.
##
## The description of the script, what it can do,
## and any further detail.
##
## @tutorial:            https://the/tutorial1/url.com
## @tutorial(Tutorial2): https://the/tutorial2/url.com
## @experimental

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


## Do something for this plugin. Before using the method
## you first have to [method initialize] [MyPlugin].[br]
## [color=yellow]Warning:[/color] Always [method clean] after use.[br]
## Usage:
## [codeblock]
## func _ready():
##     the_plugin.initialize()
##     the_plugin.do_something()
##     the_plugin.clean()
## [/codeblock]
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


