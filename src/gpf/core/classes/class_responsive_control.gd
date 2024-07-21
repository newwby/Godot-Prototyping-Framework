extends MarginContainer

class_name ResponsiveControl

##############################################################################

# Automatically sizes a Control node to the size of the viewport
# Create scenes of size_flag scaled containers beneath a top-level
#	ResponsiveControl nodes to scale everything based on the viewport

##############################################################################

#

##############################################################################

# virtual methods


func _ready():
	# set size based on current viewport size
	_setup_viewport_responsiveness()
	_on_viewport_resized()


##############################################################################

# public methods


#func example_method():
#	pass


##############################################################################

# private methods


func _on_viewport_resized():
	self.size = get_viewport_rect().size


func _setup_viewport_responsiveness():
	# set up handling for if viewport resizes
	var viewport_root: SubViewport = get_viewport()
	if viewport_root != null:
		var signal_outcome = OK
		signal_outcome = viewport_root.connect("size_changed", Callable(self, "_on_viewport_resized"))
		if signal_outcome != OK:
			GlobalLog.error(self, "err setup _on_viewport_resized")

