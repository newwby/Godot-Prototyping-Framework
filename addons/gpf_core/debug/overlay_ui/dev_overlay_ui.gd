extends ResponsiveContainer

class_name DevDebugOverlay

##############################################################################

## <class_doc>
## Inspired by debugging overlay of Minecraft (© Mojang)

#//TODO update position based on overlay_position property and position changed signal

##############################################################################

## hardcoded action key 
const SHOW_HIDE_OVERLAY_KEY := KEY_F1

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
		if event.pressed:
			if event.keycode == SHOW_HIDE_OVERLAY_KEY:
				visible = !visible
				# TESTINGG HANDLING
			elif event.keycode == KEY_F4:
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
func _populate_overlay(arg_new_debug_value) -> void:
	if arg_new_debug_value is DebugValue:
		if not arg_new_debug_value in active_debug_value_nodes:
			if not is_instance_valid(root_overlay_label):
				GlobalLog.error(self, "_populate_overlay error; root_overlay_label nullref")
			else:
				# duplicate the root (root node defaults to hidden so show the new)
				var new_dv_label = root_overlay_label.duplicate()
				label_holder_top_left.call_deferred("add_child", new_dv_label)
				new_dv_label.visible = true
				# update register
				active_debug_value_nodes[arg_new_debug_value] = new_dv_label
				# update the new label node
				_update_label(arg_new_debug_value)


func _update_label(arg_debug_value: DebugValue):
	if not arg_debug_value in active_debug_value_nodes.keys() or (arg_debug_value == null):
		GlobalLog.error(self, "DebugOverlay _update_label invalid DebugValue passed")
		return
	else:
		var debug_label = active_debug_value_nodes[arg_debug_value]
		if debug_label is Label:
			# update the overlay
			var debug_property_str = str(arg_debug_value.property)
			var debug_value_str = str(arg_debug_value.get_value())
			debug_label.text = OVERLAY_LABEL_FSTRING.format([debug_property_str, debug_value_str])


## updates values on overlay when overlay is first shown or every frame whilst
## overlay is shown
func _update_overlay() -> void:
	pass
	#new_dv_label.text = dv.get_value()
	#for dv in GlobalDebug.debug_values.values():

