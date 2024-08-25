extends MarginContainer

class_name DevDebugOverlay

##############################################################################

## <class_doc>
## Inspired by debugging overlay of Minecraft (© Mojang)

#//TODO update position based on overlay_position property and position changed signal
#//TODO update active_debug_value_nodes when DebugValues are removed
#//TODO add config/pluginb setting for show/hide overlay key

##############################################################################

## hardcoded action key to show/hide the 
const SHOW_HIDE_OVERLAY_KEY := KEY_F1
## display string for overlay labels
const OVERLAY_LABEL_FSTRING := "{0}: {1}" # property: value
## path of the overlay label root node scene
const OVERLAY_LABEL_SCENE_PATH := "res://addons/gpf_core/debug/overlay_ui/overlay_root_label.tscn"

## enable this flag to disable the overlay auto-hide behaviour
## (overlay will show on _ready)
@export var test_mode: bool = false

## root label to instance from for overlay labels
var root_overlay_label := load(OVERLAY_LABEL_SCENE_PATH)

## Register of overlay labels, stored by DebugValues.
## Is updated whenever GlobalDebug adds a new DebugValue
## Data structure is {DebugValue : Label, ...}
var active_debug_value_nodes = {}

@onready var label_holder_top_left = $VBox/Margin/HBox/ScrollLeft/VBox/TL/LabelRoot
@onready var label_holder_top_right = $VBox/Margin/HBox/ScrollRight/VBox/TR/LabelRoot
@onready var label_holder_bottom_left = $VBox/Margin/HBox/ScrollLeft/VBox/BL/LabelRoot
@onready var label_holder_bottom_right = $VBox/Margin/HBox/ScrollRight/VBox/BR/LabelRoot

##############################################################################

# virtuals

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalDebug.value_added.connect(_populate_overlay)
	visible = test_mode


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
				#print()
				#for key in active_debug_value_nodes.keys():
					#print("{0}: {1}".format([key, active_debug_value_nodes[key]]))
				#print()
				dv_test += 1
				print("yes ", dv_test)
				var pos = DebugValue.POSITION.BOTTOM_LEFT
				if dv_test %  4 == 0:
					pos = DebugValue.POSITION.BOTTOM_LEFT
				elif dv_test %  3 == 0:
					pos = DebugValue.POSITION.TOP_RIGHT
				elif dv_test %  2 == 0:
					pos = DebugValue.POSITION.TOP_LEFT
				else:
					pos = DebugValue.POSITION.BOTTOM_RIGHT
				GlobalDebug.add_debug_value(self, "dv_test", "dv_test{0}".format([dv_test]),
						"", "", pos)
				#_populate_overlay()

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
				var new_dv_label = root_overlay_label.instantiate()
				new_dv_label.name = arg_new_debug_value.property
				new_dv_label.visible = true
				# update register
				active_debug_value_nodes[arg_new_debug_value] = new_dv_label
				# update the new label node
				_update_position(arg_new_debug_value, true)
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


func _update_position(arg_debug_value: DebugValue, arg_first_call: bool = false):
	if not arg_debug_value in active_debug_value_nodes.keys() or (arg_debug_value == null):
		GlobalLog.error(self, "DebugOverlay _update_position invalid DebugValue passed")
		return
	else:
		var debug_label = active_debug_value_nodes[arg_debug_value]
		if debug_label is Label:
			# overlay position to use
			var debug_label_position = arg_debug_value.overlay_position
			# default arguments
			var new_root = null
			var text_orient_h = HORIZONTAL_ALIGNMENT_LEFT
			var text_orient_v = VERTICAL_ALIGNMENT_TOP
			
			# set text alignment and label root node based on overlay position
			match debug_label_position:
				# TL
				DebugValue.POSITION.TOP_LEFT:
					new_root = label_holder_top_left
					text_orient_h = HORIZONTAL_ALIGNMENT_LEFT
					text_orient_v = VERTICAL_ALIGNMENT_TOP
				# BL
				DebugValue.POSITION.BOTTOM_LEFT:
					new_root = label_holder_bottom_left
					text_orient_h = HORIZONTAL_ALIGNMENT_LEFT
					text_orient_v = VERTICAL_ALIGNMENT_BOTTOM
				# TR
				DebugValue.POSITION.TOP_RIGHT:
					new_root = label_holder_top_right
					text_orient_h = HORIZONTAL_ALIGNMENT_RIGHT
					text_orient_v = VERTICAL_ALIGNMENT_TOP
				# BR
				DebugValue.POSITION.BOTTOM_RIGHT:
					new_root = label_holder_bottom_right
					text_orient_h = HORIZONTAL_ALIGNMENT_RIGHT
					text_orient_v = VERTICAL_ALIGNMENT_BOTTOM
			
			# check is valid
			if is_instance_valid(new_root) and is_instance_valid(debug_label):
				#TODO get and verify current parent
				debug_label.horizontal_alignment = text_orient_h
				debug_label.vertical_alignment = text_orient_v
				if arg_first_call:
					new_root.call_deferred("add_child", debug_label)
				else:
					NodeUtility.reparent_node(debug_label.get_parent(), new_root)


## updates values on overlay when overlay is first shown or every frame whilst
## overlay is shown
func _update_overlay() -> void:
	pass
	#new_dv_label.text = dv.get_value()
	#for dv in GlobalDebug.debug_values.values():

