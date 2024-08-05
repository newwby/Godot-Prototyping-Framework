extends Container

class_name ResponsiveContainer

##############################################################################

# Automatically sizes a Container node to the size of the viewport
# Create scenes of size_flag scaled containers beneath a top-level
#	ResponsiveContainer nodes to scale everything based on the viewport

##############################################################################

#

##############################################################################

# virtual methods


func _ready():
	# set size based on current window size
	_setup_responsiveness()
	_resize_control()


##############################################################################

# public methods


#func example_method():
#	pass


##############################################################################

# private methods


func _resize_control():
	self.size = get_tree().root.size


func _setup_responsiveness():
	# set up handling for if viewport resizes
	var signal_outcome = get_tree().root.size_changed.connect(_resize_control)
	if signal_outcome != OK:
		GlobalLog.error(self, "err setup _on_viewport_resized")

