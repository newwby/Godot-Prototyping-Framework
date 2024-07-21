extends ResponsiveControl

#class_name DevActionMenu

##############################################################################

# DevActionMenu

##############################################################################

# OVERVIEW
# DevCommands are added with GlobalDebug.add_dev_command which passes via a
#	signal to the devActionMenu
#	signal passes args (caller_ref, button_name, caller_method)
#	as with debugoverlay, uses the ref as a key and creates a devActionMenu
#	object as value; the object has ref to the button (created on next idle
#	frame, before the devActionMenu object), the caller, and the method
#	when button is clicked it calls the method on the caller

# DevCommands automatically connect to caller tree exit and remove themselves
#		if the caller exits the tree
# Devs should use node-extended scripts in the scene tree storing their
#	devActionMenu scripts (see sample project) but any node can add an
#	action button in this way

#################

#//TODO
# add 'show only buttons of active group/category' (hide others)
# add group/category buttons for existing categories
# hide group/category buttons and default button if category != default
# add default exit command (shown when category != default)

##############################################################################

# Category[string] : {ActionKey[string]: {ID_ACTION: ActionMenuItem, ID_CATEGORY: String, ID_STATE: Bool}, ...}
var dev_action_register := {}
# what dev action buttons to show
var active_command_group: String = "": set = set_active_command_group
var known_command_groups := PackedStringArray([])

# action that must be pressed to show the dev action menu
# add this action to your project input map or update string to an existing action
var show_menu_action := "show_action_menu"

var is_command_line_focused := false
@onready var margin_node = $Margin
@onready var action_button_container_node = $Margin/PanelMargin/VBox/ScrollContainer/ActionButtonContainer
@onready var command_line_node = $Margin/PanelMargin/VBox/CommandContainer/HBox/CommandLine
@onready var default_dev_action_button_node = $DevActionButton
@onready var close_menu_button_node = $Margin/PanelMargin/VBox/CommandContainer/HBox/CloseMenuButton

##############################################################################

# classes

# data container
class ActionMenuItem:
	
	# identifier for the AMI
	var command_key := ""
	var command_group := ""
	
	# node references required for functionality
	var button_node_ref: Button = null: get = get_button_node_ref, set = set_button_node_ref
	var caller_node_ref: Node = null
	var caller_method_name := ""
	
	# config options
	var is_enabled := false: set = set_is_enabled
	var is_console_command_allowed := false
	var binds := [] # only for command group buttons
	var is_group_button := false: set = set_is_group_button
	
	# setup/config
	var is_valid := false
	var in_tree := false
	var is_button_join_queued := false
	
	func _init(
			arg_key: String = "",
			arg_group: String = "",
			arg_caller_node_ref: Node = null,
			arg_caller_method_name := "",
			arg_initial_state: bool = true,
			arg_button_node_ref: Button = null,
			arg_binds: Array = []):
		if arg_key == null\
		or arg_caller_node_ref == null\
		or arg_caller_method_name == "":
			is_valid = false
		else:
			self.command_key = arg_key
			self.command_group = arg_group.to_lower()
			self.caller_node_ref = arg_caller_node_ref
			self.caller_method_name = arg_caller_method_name
			self.is_enabled = arg_initial_state
			self.button_node_ref = arg_button_node_ref
			self.binds = arg_binds
			is_valid = true
	
	
	func get_button_node_ref() -> Button:
		if is_instance_valid(button_node_ref):
			return button_node_ref
		else:
			GlobalLog.error(self, "ActionMenuItem button not found (key '{0}')".format([command_key]))
			return null
	
	
	# when button is set, setup automatic behaviour for button pressing and
	#	disabling call functionality if button exits the tree
	func set_button_node_ref(arg_value: Button):
		# if button_node_ref is set whilst waiting for an orphaned button
		#	node to join the tree, the previous set attempt is abandoned
		if is_button_join_queued:
			is_button_join_queued = false
			if is_instance_valid(button_node_ref):
				button_node_ref.call_deferred("queue_free")
		
		if arg_value != null:
			if arg_value.is_inside_tree() == false:
				# wait for the orphaned button node to join tree
				is_button_join_queued = true
				await arg_value.tree_entered
				# if a new set was attempted during the wait, don't proceed
				if not is_button_join_queued:
					return
				is_button_join_queued = false
			
			# remove previous button
			var disconnect_check: int = OK
			if is_instance_valid(button_node_ref):
				# remove previous signals
				disconnect_check = GlobalFunc.multi_disconnect(button_node_ref, self,
						{"pressed": "_on_button_pressed",
						"tree_entered": "_on_button_enter_or_exit_tree",
						"tree_exited": "_on_button_enter_or_exit_tree"})
			# check signals connected
			if (disconnect_check) != OK:
				GlobalLog.error(self, "button {0} disconnect invalid, ERR {1}".format([
						button_node_ref, disconnect_check]))
			
			# set the new value
			button_node_ref = arg_value
			
			# proceed with setting up signals
			GlobalFunc.confirm_connection(button_node_ref, "tree_entered", self, "_on_button_enter_or_exit_tree")
			GlobalFunc.confirm_connection(button_node_ref, "tree_exited", self, "_on_button_enter_or_exit_tree")
			GlobalFunc.confirm_connection(button_node_ref, "pressed", self, "_on_button_pressed")
			# set up
			in_tree = button_node_ref.is_inside_tree()
	
	
	func set_is_enabled(arg_value: bool) -> void:
		is_enabled = arg_value
		if is_instance_valid(button_node_ref):
			button_node_ref.disabled = !is_enabled


	func set_is_group_button(arg_value: bool) -> void:
		is_group_button = arg_value
		if is_instance_valid(button_node_ref):
			if button_node_ref is Button:
				# command buttons should stand out fromt he rest
				button_node_ref.modulate = Color(1.25, 1.25, 1.25, 1.0)
				# command buttons should be at front of dev action menu
				var button_parent = button_node_ref.get_parent()
				if GlobalFunc.is_valid_in_tree(button_parent):
					button_parent.move_child(button_node_ref, 0)
	
	
	func remove() -> void:
		if is_instance_valid(button_node_ref):
			button_node_ref.call_deferred("queue_free")
			is_valid = false
	
	
	# returns whether the call was successful (whether the method does
	#	anything or not)
	# method 'call_dev_action'
	func run_command() -> int:
		if is_valid == false:
			GlobalLog.error(self, "dev action invalid")
			return ERR_UNCONFIGURED
		if GlobalFunc.is_valid_in_tree(caller_node_ref) == false:
			GlobalLog.error(self, "dev action node ref invalid or outside tree")
			return ERR_INVALID_PARAMETER
		if caller_node_ref.has_method(caller_method_name) == false:
			GlobalLog.error(self, "dev action method not found")
			return ERR_METHOD_NOT_FOUND
		else:
			caller_node_ref.callv(caller_method_name, binds)
			return OK
	
	
	func _on_button_enter_or_exit_tree():
		in_tree = button_node_ref.is_inside_tree()
	
	
	func _on_button_pressed():
		if run_command() != OK:
			GlobalLog.error(self, "dev command {0} failed to execute command".format([command_key]))


##############################################################################

# setters/getters


# if passed nilstring will opt for no group (default group)
func set_active_command_group(arg_new_value: String) -> void:
	if arg_new_value == "":
		arg_new_value = GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP.to_lower()
	active_command_group = arg_new_value
	# set button visbility based on active command group
	if dev_action_register.is_empty():
		return
	else:
		var ami_object = null
		var ami_button: Button = null
		var is_visible: bool
		for ami_key in dev_action_register.keys():
			ami_object = dev_action_register[ami_key]
			if ami_object is ActionMenuItem:
				ami_button = ami_object.button_node_ref
				is_visible = (ami_object.command_group == active_command_group)
				if is_instance_valid(ami_button):
					ami_button.visible = is_visible


##############################################################################

# virt


func _ready():
	# cannot be set at init as this script is attached to a child node
	#	of GlobalDebug (and will be loaded before GlobalDebug has a chance
	#	to initialise)
	_change_active_command_group(GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP)
	
	# setup debug overlay
	GlobalFunc.confirm_connection(GlobalDebug, "debug_mode_changed", self, "_on_debug_mode_changed")
	default_dev_action_button_node.visible = false
	self.visible = false
	if not InputMap.has_action(show_menu_action):
		GlobalLog.error(self, "project has not assigned show menu action")
	#
	# establish connections to public singleton call methods for DevActionmenu
	var signal_setup_pairs := {
		"add_dev_command": "_on_add_dev_command",
		"remove_dev_command": "_on_remove_dev_command",
		}
	var value = ""
	for key in signal_setup_pairs:
		value = signal_setup_pairs[key]
		if GlobalFunc.confirm_connection(GlobalDebug, key, self, value) != OK:
			GlobalLog.error(self, "Cheat Setup Error | Error Code {0}-{1}".\
					format([GlobalDebug.has_signal(key), self.has_method(value)]))


func _input(event):
	if GlobalDebug.enable_debug_mode == false:
		return
	elif event.is_action_pressed(show_menu_action):
		if visible == false:
			show_menu()
		else:
			hide_menu()
	elif event.is_action_pressed("ui_accept") and is_command_line_focused:
		_on_send_command_button_pressed()


##############################################################################

# public


func add_command_group(arg_group: String) -> void:
	if arg_group.to_lower() in known_command_groups:
		return
	# don't add a default category button
	elif arg_group.to_lower() != GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP:
		known_command_groups.append(arg_group.to_lower())
		_add_parent_command_button(arg_group.to_lower())


func hide_menu() -> void:
	self.visible = false
	_change_active_command_group(GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP)


func show_menu() -> void:
	close_menu_button_node.grab_focus()
	self.visible = true


##############################################################################

# private


func _add_parent_command_button(arg_new_group_id := "") -> void:
	if arg_new_group_id == "":
		GlobalLog.error(self, "_add_parent_command_button error; cannot add blank group id")
		return
	else:
		if dev_action_register.has(arg_new_group_id):
			GlobalLog.error(self, "_add_parent_command_button error; group_id exists as devcommand")
			return
		else:
			# add group id as a bind for _change_active_command_group
			_on_add_dev_command(arg_new_group_id, self,
					"_change_active_command_group", GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP.to_lower(),
					true, true, true, [arg_new_group_id.to_lower()])
			var exit_string := "Exit "+str(arg_new_group_id)
			_on_add_dev_command(exit_string, self,
					"_reset_active_command_group", arg_new_group_id)
			# make the command group buttons for entering/exiting submenus
			#	stand out a bit
			# (first wait for above methods to complete)
			await get_tree().idle_frame
			for ami_id in [arg_new_group_id.to_lower(), exit_string]:
				if dev_action_register.has(ami_id) == false:
					GlobalLog.warning(self, "_add_parent_command_button couldn't find {0} in dev_action_register".\
							format([ami_id]))
				var get_ami = dev_action_register[ami_id]
				if get_ami is ActionMenuItem:
					get_ami.is_group_button = true


# if left with no argument will revert to default
func _change_active_command_group(arg_new_group := "") -> void:
	if arg_new_group == "":
		GlobalLog.warning(self, "_change_active_command_group unspecified group, using default")
		arg_new_group = GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP.to_lower()
	self.active_command_group = arg_new_group.to_lower()


func _is_in_active_command_group(arg_ami: ActionMenuItem = null) -> bool:
	if is_instance_valid(arg_ami) == false:
		GlobalLog.error(self, "_is_in_active_command_group called with invalid ActionMenuItem; {0}".format([arg_ami]))
		return false
	else:
		return (arg_ami.command_group.to_lower() == active_command_group.to_lower())


# arg_binds is only used for parent devcommand buttons
func _on_add_dev_command(
		arg_key: String,
		arg_caller: Object,
		arg_caller_method: String,
		arg_group: String,
		arg_initial_state: bool = true,
		arg_add_menu_button: bool = true,
		arg_add_console_command: bool = true,
		arg_binds := []) -> void:
	var new_action_menu_item: ActionMenuItem = null
	
	if not arg_add_menu_button:
		new_action_menu_item =\
				ActionMenuItem.new(arg_key, arg_group,
						arg_caller, arg_caller_method,
						arg_initial_state)
	else:
		var new_action_menu_button = default_dev_action_button_node.duplicate()
		action_button_container_node.call_deferred("add_child", new_action_menu_button)
		await new_action_menu_button.tree_entered
		new_action_menu_button.text = arg_key
		new_action_menu_item =\
				ActionMenuItem.new(arg_key, arg_group, arg_caller, arg_caller_method,
				arg_initial_state, new_action_menu_button, arg_binds)
		new_action_menu_button.visible = _is_in_active_command_group(new_action_menu_item)
	# add dev command
	if is_instance_valid(new_action_menu_item):
		new_action_menu_item.is_console_command_allowed = arg_add_console_command
		dev_action_register[arg_key] = new_action_menu_item
		if not new_action_menu_item.command_group in known_command_groups:
			add_command_group(new_action_menu_item.command_group)


func _on_remove_dev_command(arg_key: String) -> void:
	var action_item = null
	if dev_action_register.has(arg_key):
		action_item = dev_action_register[arg_key]
		if is_instance_valid(action_item):
			var command_group = ""
			if action_item is ActionMenuItem:
				command_group = action_item.command_group
				action_item.remove()
			if dev_action_register.erase(arg_key) == false:
				GlobalLog.error(self, "error removing dev_action_register entry {0}".format([arg_key]))
			else:
				if _does_group_exist(command_group) == false:
					_remove_command_group(command_group)
	else:
		GlobalLog.error(self, " _on_remove_dev_command could not find dev command '{0}'".format([arg_key]))


func _does_group_exist(arg_group: String) -> bool:
	if arg_group == ""\
	or arg_group == GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP:
		return true
	else:
		for devcommand in dev_action_register.values():
			if devcommand is ActionMenuItem:
				if devcommand.command_group.to_lower() == arg_group.to_lower():
					if devcommand.is_group_button == false:
						return true
		return false


func _on_close_menu_button_pressed():
	self.visible = false


func _on_command_line_focus_entered():
	is_command_line_focused = true


func _on_command_line_focus_exited():
	is_command_line_focused = false


func _on_debug_mode_changed(arg_is_enabled: bool) -> void:
	if arg_is_enabled == false and visible == true:
		visible = false


func _on_send_command_button_pressed():
	_parse_dev_command(command_line_node.text)


# arg_command should correspond to the given ActionMenuItem key (which
#	was set in add_dev_command)
func _parse_dev_command(arg_command: String):
	command_line_node.text = ""
	var command_action_menu_item = null
	if not arg_command in dev_action_register.keys():
		GlobalLog.info(self, "command {0} not found".format([arg_command]))
		return
	else:
		command_action_menu_item = dev_action_register[arg_command]
		if is_instance_valid(command_action_menu_item):
			if command_action_menu_item is ActionMenuItem:
				if command_action_menu_item.is_console_command_allowed:
					if command_action_menu_item.run_command() != OK:
						GlobalLog.error(self, "key exists but command invalid")
						return
	# else
	GlobalLog.error(self, "_parse_dev_command validation error for command '{0}'".format([arg_command]))


func _remove_command_group(arg_group: String):
	if arg_group != ""\
	and arg_group != GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP:
		var index = known_command_groups.find(arg_group)
		if index != -1:
			known_command_groups.remove(index)
		for devcommand in dev_action_register.values():
			if devcommand is ActionMenuItem:
				if devcommand.command_group.to_lower() == arg_group.to_lower()\
				or devcommand.command_key.to_lower() == arg_group.to_lower():
					_on_remove_dev_command(devcommand.command_key)


func _reset_active_command_group() -> void:
	_change_active_command_group(GlobalDebug.ID_DEFAULT_DEV_ACTION_GROUP.to_lower())


# make sure leftover command groups enter/exit buttons don't exist
func _update_command_groups() -> void:
	var group_button_exists := false
	for group in known_command_groups:
		for devcommand in dev_action_register.values():
			if devcommand is ActionMenuItem:
				if devcommand.command_group.to_lower() == group.to_lower()\
				and devcommand.is_group_button == false:
					group_button_exists = true
					break
		if group_button_exists == false:
			_remove_command_group(group)
