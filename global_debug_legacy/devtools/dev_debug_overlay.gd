extends ResponsiveControl

#class_name DevDebugOverlay

##############################################################################

# Call GlobalDebug.update_debug_overlay(*args) with key and value
# If the key already exists, DevDebugOverlay will push an update to the
# matching debug overlay item container, changing the value as appropriate.
# If the key is not found, DevDebugOverlay will create a new debug item
# container on the next idle frame and then update as normal

##############################################################################

# debug_key : debug_overlay_item object
# stores references to the DebugOverlayItem (local class) object that stores
#	relevant properties about the overlay item
var debug_overlay_item_register = {}

# action that must be pressed to show the debug overlay
# add this action to your project input map or update string to an existing action
var show_menu_action := "show_debug_menu"

# debug items cannot be updated until the frame after the request to create them
#	(e.g. when their respective overlay node container has joined the tree or
#	when the container is being reparented)
var queued_overlay_item_nodes := []

# duplicated to create debug_overlay_item nodes
@onready var default_overlay_item_node = $Margin/OverlayItem
@onready var margin_node = $Margin
# positional containers for debug_overlay_item nodes
@onready var position_container_top_left: VBoxContainer = $Margin/Align/Top/Left
@onready var position_container_top_mid: VBoxContainer = $Margin/Align/Top/Mid
@onready var position_container_top_right: VBoxContainer = $Margin/Align/Top/Right
@onready var position_container_bottom_left: VBoxContainer = $Margin/Align/Bottom/Left
@onready var position_container_bottom_mid: VBoxContainer = $Margin/Align/Bottom/Mid
@onready var position_container_bottom_right: VBoxContainer = $Margin/Align/Bottom/Right

##############################################################################

# classes


# data container
class DebugOverlayItem:
	
	var key_node_ref: Label = null
	var value_node_ref: Label = null
	var container_node_ref: HBoxContainer = null
	var key := ""
	var value = null
	var is_valid := false
	
	func _init(
			arg_container_node_ref: HBoxContainer = null,
			arg_key_node_ref: Label = null,
			arg_value_node_ref: Label = null,
			arg_key: String = "",
			arg_value = null):
		if arg_container_node_ref == null\
		or arg_key_node_ref == null\
		or arg_value_node_ref == null\
		or arg_key == "":
			GlobalLog.error(self, "DebugOverlayItem failed setup")
			is_valid = false
		else:
			self.container_node_ref = arg_container_node_ref
			self.key_node_ref = arg_key_node_ref
			self.value_node_ref = arg_value_node_ref
			self.key = arg_key
			self.value = arg_value
			is_valid = true


# update label nodes (stored by reference) by stored value
	func update_labels():
		if not is_valid:
			return
		if key_node_ref != null:
			key_node_ref.text = key
		if value_node_ref != null:
			value_node_ref.text = str(value)


##############################################################################

# virt


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalFunc.confirm_connection(GlobalDebug, "debug_mode_changed", self, "_on_debug_mode_changed")
	self.visible = false
	default_overlay_item_node.visible = false
	var signal_outcome = GlobalFunc.confirm_connection(GlobalDebug,
			"update_debug_overlay_item", self, "_on_update_debug_overlay_item") 
	if signal_outcome != OK:
		GlobalLog.error(self, "DebugOverlay err setup update_debug_overlay_item")
	if not InputMap.has_action(show_menu_action):
		GlobalLog.error(self, "project has not assigned show menu action")


func _input(event):
	if GlobalDebug.enable_debug_mode == false:
		return
	elif event.is_action_pressed(show_menu_action):
		self.visible = !self.visible


##############################################################################

# public


# returns the VBoxContainer corresponding to the given value in
#	the enum GlobalDebug.FLAG_OVERLAY_POSITION
func get_debug_item_container(arg_position_value: int) -> VBoxContainer:
	if arg_position_value in GlobalDebug.FLAG_OVERLAY_POSITION.values():
		match arg_position_value:
			GlobalDebug.FLAG_OVERLAY_POSITION.TOP_LEFT:
				return position_container_top_left
			GlobalDebug.FLAG_OVERLAY_POSITION.TOP_MID:
				return position_container_top_mid
			GlobalDebug.FLAG_OVERLAY_POSITION.TOP_RIGHT:
				return position_container_top_right
			GlobalDebug.FLAG_OVERLAY_POSITION.BOTTOM_LEFT:
				return position_container_bottom_left
			GlobalDebug.FLAG_OVERLAY_POSITION.BOTTOM_MID:
				return position_container_bottom_mid
			GlobalDebug.FLAG_OVERLAY_POSITION.BOTTOM_RIGHT:
				return position_container_bottom_right
	# else/catchall
	return null


##############################################################################

# private


# called from _on_update_debug_overlay_item
# creates both a new DebugOverlayItem object and the companion overlay_item node
# if arg_position_value is negative it will be ignored and
#	default_overlay_item_position will be used instead
func _add_item(
		arg_item_key: String,
		arg_item_value,
		arg_position_value: int = GlobalDebug.FLAG_OVERLAY_POSITION.TOP_RIGHT) -> void:
	queued_overlay_item_nodes.append(arg_item_key)
	# get area of overlay to add the new item
	var overlay_container = get_debug_item_container(arg_position_value)
	var new_overlay_node = default_overlay_item_node.duplicate()
	overlay_container.call_deferred("add_child", new_overlay_node)
	await new_overlay_node.tree_entered
	new_overlay_node.visible = true
	# get the node references, check are valid, remove if not
	var key_label_node_ref = new_overlay_node.get_node_or_null("Key")
	var value_label_node_ref = new_overlay_node.get_node_or_null("Value")
	if key_label_node_ref == null or value_label_node_ref == null:
		GlobalLog.error(self, "err setup _add_item key/value node == null"+\
				"| key: {0} & value: {1}".format([key_label_node_ref, value_label_node_ref]))
		new_overlay_node.get_parent().call_deferred("remove_child", new_overlay_node)
		queued_overlay_item_nodes.erase(arg_item_key)
		return
	# if setup of node was successful, create the reference object to store info
	var new_overlay_object = DebugOverlayItem.new(new_overlay_node,
			key_label_node_ref, value_label_node_ref, arg_item_key, arg_item_value)
	new_overlay_object.update_labels()
	# record by key
	debug_overlay_item_register[arg_item_key] = new_overlay_object
	queued_overlay_item_nodes.erase(arg_item_key)


func _on_debug_mode_changed(arg_is_enabled: bool) -> void:
	if arg_is_enabled == false and visible == true:
		visible = false


# on GlobalDebug signal update_debug_overlay_item
# can only set debug_overlay_item position on first call; if arg_item_position
#	is invalid, position will default to TOP_LEFT for new nodes
func _on_update_debug_overlay_item(arg_item_key, arg_item_value, arg_item_position) -> void:
	# if waiting to add a new overlay node to tree, delay processing
	if arg_item_key in queued_overlay_item_nodes:
		await get_tree().idle_frame
		_on_update_debug_overlay_item(arg_item_key, arg_item_value, arg_item_position)
	else:
		# get default position if passed invalid argument
		var container_position := 0
		if not arg_item_position in GlobalDebug.FLAG_OVERLAY_POSITION.values():
			container_position = GlobalDebug.FLAG_OVERLAY_POSITION.TOP_LEFT
		if typeof(arg_item_key) == TYPE_STRING:
			if arg_item_key in debug_overlay_item_register.keys():
				_update_item(arg_item_key, arg_item_value)
			else:
				_add_item(arg_item_key, arg_item_value, container_position)


# called from _on_update_debug_overlay_item
func _update_item(arg_item_key: String, arg_item_value):
	var overlay_object: DebugOverlayItem = null
	if debug_overlay_item_register.has(arg_item_key):
		overlay_object = debug_overlay_item_register[arg_item_key]
		if overlay_object != null:
			overlay_object.value = arg_item_value
			overlay_object.update_labels()

