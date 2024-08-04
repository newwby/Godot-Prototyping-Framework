extends GameGlobal

#class_name GlobalDebug

##############################################################################

# GlobalDebug allows developers to expose game properties during release
# builds, through developer commands and a debugging overlay.

##############################################################################

# the debug info overlay is a child scene of GlobalDebug which is hidden
# by default in release builds (and visible by default in debug builds),
# consisting of a vbox column of key/value label node pairs on the side
# of the viewport. This allows the developer to set signals or setters within
# their own code to automatically push changes in important values to somewhere
# visible ingame. This is useful to get feedback in unstable release builds.
signal update_debug_overlay_item(item_key, item_value, item_position)

# key is the keyword to use to activate a dev command
# caller is who owns the dev command method (ideally a singleton)
# method is the behaviour to call when the dev command is activated
# group is used for organising sub buttons under a parent button;
#	if group is left unspecified it will be set to 'default'
#	if no group parent command has been activated, available commands are those under 'default' group
#	if a group parent command is activated, available commands are those under that command only,
#		until the exit command is sent or the menu is closed
# initial state determines whether to enable/disable the dev command at first
# add_button_command will enable ui access (and add a button to the DevActionMenu) for the command
# add_text_command will enable text command access for the command
# binds are optional arguments to be passed to the caller method (fixed per dev command instance)
signal add_dev_command(key, caller, method, group, initial_state, add_button_command, add_text_command, binds)
signal remove_dev_command(key)

signal debug_mode_changed(is_enabled)

# GlobalDebug pushes engine FPS to overlay by default
const ENABLE_FPS_LOGGING := true

const ID_DEFAULT_DEV_ACTION_GROUP := "default"

# where on-screen to position a debug_overlay_item
# passed alongside update_debug_overlay_item signal
enum FLAG_OVERLAY_POSITION {
		TOP_LEFT, TOP_MID, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_MID, BOTTOM_RIGHT}

var enable_debug_mode := false: set = _set_enable_debug_mode

###############################################################################

# virt


func _set_enable_debug_mode(arg_value: bool):
	enable_debug_mode = arg_value
	emit_signal("debug_mode_changed", arg_value)


###############################################################################

# virt


func _ready():
	if verbose_logging:
		GlobalLog.elevate_log_permissions(self)


func _process(_delta):
	if ENABLE_FPS_LOGGING:
		update_debug_overlay("fps", Engine.get_frames_per_second())


###############################################################################


# passes to DevActionMenu
func add_dev_command(
		arg_key: String,
		arg_caller: Object,
		arg_caller_method: String,
		arg_group: String = ID_DEFAULT_DEV_ACTION_GROUP,
		arg_initial_state: bool = true,
		arg_add_menu_button: bool = true,
		arg_add_console_command: bool = true,
		arg_binds: Array = []):
	emit_signal("add_dev_command",
			arg_key, arg_caller, arg_caller_method, arg_group, arg_initial_state,
			arg_add_menu_button, arg_add_console_command, arg_binds)


# passes to DevActionMenu, fully deletes dev command from DevActionMenu
func remove_dev_command(arg_key: String) -> void:
	emit_signal("remove_dev_command", arg_key)


# updates a value on the debug overlay or creates a new key/value pair if
#	the given overlay_item_key does not exist
# arg_overlay_position sets where on-screen to show the overlay item;
#	if it already exists it will be moved to there
# passes to DevDebugOverlay
func update_debug_overlay(
		arg_overlay_item_key: String,
		arg_overlay_item_value,
		arg_overlay_position: int = FLAG_OVERLAY_POSITION.TOP_RIGHT) -> void:
	emit_signal("update_debug_overlay_item",
			arg_overlay_item_key,
			arg_overlay_item_value,
			arg_overlay_position)


###############################################################################

# private

