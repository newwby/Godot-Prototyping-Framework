extends MarginContainer

class_name DevDebugOverlay

##############################################################################

## <class_doc>
## Inspired by debugging overlay of Minecraft (© Mojang)

#//TODO update position based on overlay_position property and position changed signal

##############################################################################

const OVERLAY_LABEL_FSTRING := "{0}: {1}" # property: value

# DebugValue : Label
var active_debug_value_nodes = {}

@onready var root_overlay_label = $Margin/TopLeftRoot/OverlayRootLabel
@onready var label_holder_top_left = $Margin/TopLeftRoot

##############################################################################

# virtuals

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalDebug.value_added.connect(_populate_overlay)


#===========================================
# For testing only
#//TODO remove
var dv_test = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F4 and event.pressed:
			print("yes ", dv_test)
			GlobalDebug.add_debug_value(self, "dv_test", "dv_test{0}".format([dv_test]))
			#_populate_overlay()
			dv_test += 1
#===========================================


##############################################################################

# private


## creates label nodes for overlay
## each label node is parented underneath a specific container that controls
## its position on the overlay, based on the overlay_position property
func _populate_overlay(arg_new_dv) -> void:
	if arg_new_dv is DebugValue:
		if not arg_new_dv in active_debug_value_nodes:
			if is_instance_valid(root_overlay_label):
				var new_dv_label = root_overlay_label.duplicate()
				label_holder_top_left.call_deferred("add_child", new_dv_label)
				new_dv_label.visible = true
				active_debug_value_nodes[arg_new_dv] = new_dv_label
				new_dv_label.text = OVERLAY_LABEL_FSTRING.format([arg_new_dv.property, arg_new_dv.get_value()])


## updates values on overlay when overlay is first shown or every frame whilst
## overlay is shown
func _update_overlay() -> void:
	pass
	#new_dv_label.text = dv.get_value()
	#for dv in GlobalDebug.debug_values.values():

