extends Node

class_name GameGlobal

##############################################################################
#
# GameGlobal is the base class of all DDAT Globals
# Its purpose is twofold.
#	1) Avoid duplication of code between globals.
#	2) Allow configuration options to be easily set on all globals.
#

#//TODO
# remove preload or rework agnostic of the runtime framework

##############################################################################

# variants go here

var verbose_logging := false

##############################################################################

# virt

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	_preload()
	# globals shouldn't logspam
#	GlobalLog.change_log_permissions(self, false)


###############################################################################

# public


#


###############################################################################

# private

# shadow this in derived classes
# this method is called by the preload handler as part of the runtime framework
# individual singletons that need to load from disk can signal to globalData
# to load their required resources at this time.
func _preload():
	pass


###############################################################################

