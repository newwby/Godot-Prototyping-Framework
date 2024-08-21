extends MarginContainer

const OVERLAY_LABEL_FSTRING := "{0}: {1}" # property: value

# DebugValue : Label
var active_debug_value_nodes = {}

@onready var root_overlay_label = $Margin/TopLeftRoot/OverlayRootLabel
@onready var label_holder_top_left = $Margin/TopLeftRoot

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var dv_test = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F4 and event.pressed:
			print("yes ", dv_test)
			GlobalDebug.add_debug_value(self, "dv_test", "dv_test{0}".format([dv_test]))
			_populate_overlay()
			dv_test += 1


func _populate_overlay() -> void:
	for dv in GlobalDebug.debug_values.values():
		if dv is DebugValue:
			if not dv in active_debug_value_nodes:
				if is_instance_valid(root_overlay_label):
					var new_dv_label = root_overlay_label.duplicate()
					label_holder_top_left.call_deferred("add_child", new_dv_label)
					new_dv_label.visible = true
					active_debug_value_nodes[dv] = new_dv_label
					new_dv_label.text = OVERLAY_LABEL_FSTRING.format([dv.property, dv.get_value()])


func _update_overlay() -> void:
	pass
	#new_dv_label.text = dv.get_value()

