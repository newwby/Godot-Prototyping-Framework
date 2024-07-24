extends Node

#class_name GlobalLog

##############################################################################

#//TODO implement asynchronous logging (send to buffer, log over time)
#	- some concern with output order for critical logs
#		(what if they are sent after the fatal error and never seen?)
#		solution - if a critical log is sent, dump the entire buffer to console then critical log
#			(because buffer should never be absurd, multiple messages a frame should be cleared)
#			(asynchronous should also be an optional flag)

#//TODO
# restore log to disk functionality

#	const USER_LOG_DIRECTORY = "user://logs/gpf_logger"
#	log_to_disk_setting == LOG_TO_DISK_OPTION.ALWAYS
#	var runtime_log_directory_name =\
		#"user://"+USER_LOG_DIRECTORY+"uncategorised"
	# setup log saving directory
#	runtime_log_directory_name =\
#			GlobalData.get_dirpath_user()+USER_LOG_DIRECTORY+"/"+\
#			Time.get_datetime_string_from_system(false, false).\
#			replace("T", "_").replace("-", "_").replace(":", "_")

##############################################################################

# Logs are one of the following types
# CRITICAL logs raise debugger errors, print to console, and stop program execution (debug mode only)
# ERROR logs raise debugger errors and print to console
# WARNING logs raise debugger warnings and print to console
# INFO logs simply print to console and do nothing else
enum CODE {UNDEFINED, CRITICAL, ERROR, WARNING, INFO}

# initial log message
const STARTUP_LOG_FSTRING := "[{device}] Logger service ready @ {time}"
# format of a log
const LOG_FSTRING := "[t{time}] {caller}\t[{type}] | {message}"

@export var record_logs := true

# user control for how logs are handled; caution - at least one of these flags
#	must be enabled or else calling log methods won't actually do anything!
# allow_log_output must be enabled for logs to printed to console/log file (_output_log)
# allow_log_registration must be enabled for logs to be saved (_store_log)
var allow_log_output := true
var allow_log_registration := true

# LOG RECORDING
# total logs registered this runtime
# (split by whether they were output to console or not)
var total_log_calls := 0
var total_log_output := 0

# record of who logged what and when
# nothing is recorded if record_logs is set to false
var log_register = {}

# LOG PERMISSIONS
# Permissions enable blocking different objects from making log calls or
#	only enabling some logs from being recorded if a permisison flag is set
# There are three permissions states;
#	default permission, elevated permission (true), and no/blocked permission (false)
# Null (Default) - logs with calls to the standard log methods will be sent
# True (Elevated) - as default but calls to the debug_ prefixed log methods will be sent as well
# False (Blocked) - no calls will be sent

# use to enable or disable log permissions on a per script basis
# call _change_permission to modify
# if an object isn't in log_permissions their permissions default to allowed
var log_permissions = {}
# where record of last log permission state is kept if storing state when
#	changing log permissions
var _log_permissions_last_state = {}

##############################################################################


class LogRecord:
	var owner: Object
	var timestamp: int
	var log_code_id: int
	var log_code_name: String
	var log_message: String
	var logged_to_console: bool = false
	# log saving deprecated
	#var saved_to_disk: bool = false
	var full_log_string: String
	
	func _init(
			arg_owner: Object,
			arg_log_timestamp: int,
			arg_log_code_id: int,
			arg_log_code_name: String,
			arg_log_message: String,
			arg_log_string: String
			):
		self.owner = arg_owner
		self.timestamp = arg_log_timestamp
		self.log_code_id = arg_log_code_id
		self.log_code_name = arg_log_code_name
		self.log_message = arg_log_message
		self.full_log_string = arg_log_string


##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	# logger prevents automatic quit on notification
	get_tree().set_auto_accept_quit(false)
	# logger is always allowed to log about self
	# (parent gameGlobal class, for ddat-gpf singletons, disables by default)
	_change_permission(self, true)
	# print startup info
	_on_logger_startup()


# deprecated behaviour for log saving to disk
## hijack the exit process to force save logs to disk on quit
## get_tree().quit() will skip this behaviour
#func _notification(what):
	#if what == NOTIFICATION_WM_CLOSE_REQUEST:
##		get_tree().quit()


##############################################################################

# public methods


# see _log for parameter explanation
# Critical should only be called where you need the program to stop execution
#	if this line is reached (e.g. on encountering a fatal flaw); prefer use of
#	'error' call rather than this call otherwise.
func critical(
		arg_caller: Object,
		arg_error_message,
		arg_show_on_elevated_only: bool = false) -> void:
	_log(arg_caller, arg_error_message, 1, arg_show_on_elevated_only)


# debug ('elevated') logs only appear in the debugger/output/console if the object
#	emitting the log has had their logging permissions elevated
# use debug/elevated logs to hide logs you only need when debugging
func debug_critical(arg_caller: Object, arg_error_message) -> void:
	critical(arg_caller, arg_error_message, true)


# debug ('elevated') logs only appear in the debugger/output/console if the object
#	emitting the log has had their logging permissions elevated
# use debug/elevated logs to hide logs you only need when debugging
func debug_error(arg_caller: Object, arg_error_message) -> void:
	error(arg_caller, arg_error_message, true)


# debug ('elevated') logs only appear in the debugger/output/console if the object
#	emitting the log has had their logging permissions elevated
# use debug/elevated logs to hide logs you only need when debugging
func debug_info(arg_caller: Object, arg_error_message) -> void:
	info(arg_caller, arg_error_message, true)


# debug ('elevated') logs only appear in the debugger/output/console if the object
#	emitting the log has had their logging permissions elevated
# use debug/elevated logs to hide logs you only need when debugging
func debug_warning(arg_caller: Object, arg_error_message) -> void:
	warning(arg_caller, arg_error_message, true)


# see _log for parameter explanation
func error(
		arg_caller: Object,
		arg_error_message,
		arg_show_on_elevated_only: bool = false) -> void:
	_log(arg_caller, arg_error_message, 2, arg_show_on_elevated_only)


func get_permission(arg_caller: Object) -> bool:
	var permission_allowed = true
	if arg_caller in log_permissions.keys():
		permission_allowed = log_permissions[arg_caller]
		if typeof(permission_allowed) != TYPE_BOOL:
			error(self, "invalid permission type for {0}".format([arg_caller]))
			return false
	# otherwise isn't blocked
	return permission_allowed


# see _log for parameter explanation
func info(
		arg_caller: Object,
		arg_error_message,
		arg_show_on_elevated_only: bool = false) -> void:
	_log(arg_caller, arg_error_message, 4, arg_show_on_elevated_only)


# arguments as _log but accepts caller but does not accept error_message
# does nothing if not in a debug build
func log_stack_trace(arg_caller: Object) -> void:
	if OS.is_debug_build():
		var full_stack_trace = get_stack()
		var error_stack_trace = full_stack_trace[1]
		var error_func_id = error_stack_trace["function"]
		var error_node_id = error_stack_trace["source"]
		var error_line_id = error_stack_trace["line"]
		var stack_trace_print_string =\
				"\nStack Trace: [{f}] [{s}] [{l}]".format({\
					"f": error_func_id,
					"s": error_node_id,
					"l": error_line_id})
		GlobalLog.trace(arg_caller, stack_trace_print_string)


# sets the last log permission state stored by the caller key
# removes the stored log permission state if returned
# returns err code if caller hasn't previously stored a log permission state
func reset_permission(arg_caller: Object) -> int:
	if arg_caller in _log_permissions_last_state.keys():
		_change_permission(
				arg_caller, _log_permissions_last_state[arg_caller])
		_log_permissions_last_state.erase(arg_caller)
		return OK
	else:
		return ERR_INVALID_PARAMETER


# allows logging permission to the object specified by argument
# standard logs (logs with the 'is_elevated' arg set to false) will show for 
#	the console if the caller has enabled permissions, but elevated (see
#	'set_permission_elevated') logs will not
# by default objects are assumed to have enabled log permissions
func set_permission_default(
		arg_caller: Object,
		arg_store_permission: bool = false) -> void:
	if arg_store_permission:
		store_permission(arg_caller)
	_change_permission(arg_caller, null)


# blocks logging permission to the object specified by argument
# no logs will show in console if log permissions are disabled
func set_permission_disabled(
		arg_caller: Object,
		arg_store_permission: bool = false) -> void:
	if arg_store_permission:
		store_permission(arg_caller)
	_change_permission(arg_caller, false)


# applies elevated permission to the object specified by argument
# elevated logs (logs with the 'is_elevated' arg set to true) will show in
#	the console only if the caller has elevated permissions
# if arg_store_permission is set true, will record the current log permission
#	before seting the new permission (see 'store_permission')
func set_permission_elevated(
		arg_caller: Object,
		arg_store_permission: bool = false) -> void:
	if arg_store_permission:
		store_permission(arg_caller)
	_change_permission(arg_caller, true)


# get the current log permission state of a caller and save it to the
#	_log_permissions_last_state so it can later be recalled
func store_permission(arg_caller: Object) -> void:
	if arg_caller in log_permissions.keys():
		_log_permissions_last_state[arg_caller] = log_permissions[arg_caller]
	else:
		_log_permissions_last_state[arg_caller] = null


# see _log for parameter explanation
func warning(
		arg_caller: Object,
		arg_error_message,
		arg_show_on_elevated_only: bool = false) -> void:
	_log(arg_caller, arg_error_message, 3, arg_show_on_elevated_only)


##############################################################################

# private methods


# method allows blocking specific scripts from making log calls
# (useful for scripts whose debugging logs spam the console)
# arg_caller should be the object you wish to allow or disallow logging from
# arg_permission adjusts whether logs are output to console or not
#	true = all logs, including elevated logs (see _log)
#	null = default permission, as though this had never been called
#	false = no logs
# if arg_permission is not null or a bool, this method does nothing
func _change_permission(arg_caller: Object, arg_permission) -> void:
	if arg_permission == null and log_permissions.has(arg_caller):
		log_permissions.erase(arg_caller)
	elif typeof(arg_permission) == TYPE_BOOL:
		log_permissions[arg_caller] = arg_permission


# get whether an object is allowed to make logging calls (output to console)
# see '_change_permission' method
# if an object isn't present in log_permissions, they have default logging
# default logging = regular logs go through, elevated do not
# if permissions are 'true', all logs (including elevated) go through
# if permissions are 'false', no logs go through
func _is_permitted(
		arg_log_caller: Object,
		arg_show_on_elevated_only: bool) -> bool:	
	var permission_state
	if not arg_log_caller in log_permissions.keys():
		permission_state = null
	else:
		assert(arg_log_caller in log_permissions.keys())
		permission_state = log_permissions[arg_log_caller]
		assert(typeof(permission_state) == TYPE_BOOL)
	# 
	if permission_state == null:
		return !arg_show_on_elevated_only
	else:
		return permission_state


# main logging method
# prints to console or pushes a warning/error
# arg_caller = object (or null) that sent the log call
# arg_error_message = value that will be converted to string and sent with the
#	the log; if it is a valid error enum entry the error_string will be fetched instead
# arg_log_code = the log type, see CODE for explanations of use
# arg_show_on_elevated_only = argument for log_permisisons; see _change_permission
func _log(
		arg_caller: Object,
		arg_error_message,
		arg_log_code: int = 0,
		arg_show_on_elevated_only: bool = false
		) -> void:
	# check the log type is valid (see ALLOW_ consts/_is_log_type_allowed
	# method and log_permission dict)
	#if not _is_log_type_allowed(arg_log_code):
		#return
	if not _is_permitted(arg_caller, arg_show_on_elevated_only):
		return
	
	var caller_id: String = str(arg_caller)
	var full_error_message: String
	
	# check if is error constant from Error enum
	if typeof(arg_error_message) == TYPE_INT:
		full_error_message = error_string(arg_error_message)
		# for invalid error codes just return the integer
		if full_error_message == "(invalid error code)":
			full_error_message = str(arg_error_message)
	else:
		full_error_message = str(arg_error_message)
	
	# get error type
	var log_code_id: int =\
			arg_log_code if arg_log_code in CODE.values() else 0
	var log_code_name: String = str(CODE.keys()[log_code_id])
	
	var log_timestamp = Time.get_ticks_msec()
	
	var full_log_string = LOG_FSTRING.format({
				"type": log_code_name,
				"time": log_timestamp,
				"caller": str(caller_id),
				"message": str(full_error_message)
				})
		
	var log_record: LogRecord = null
	log_record = LogRecord.new(arg_caller, log_timestamp, log_code_id,
			log_code_name, full_error_message, full_log_string)
	
	# once a log record has been created, the log call is considered complete
	# storage and output are handled afterwards
	if is_instance_valid(log_record):
		total_log_calls += 1
	
	## log storing is disabled if allow_log_registration is false
	_store_log(log_record)
	
	#//TODO implement log buffer here - some concern with output order for
	#	critical logs (see todo at top of file for how to resolve)
	## log output is disabled if allow_log_output flag is false
	_output_log(log_record)


func _on_logger_startup() -> void:
	# get basic information on the user
	var user_datetime = Time.get_datetime_dict_from_system()
	
	# convert the user datetime into something human-readable
	var user_date_as_string =\
			str(user_datetime["year"])+\
			"/"+str(user_datetime["month"])+\
			"/"+str(user_datetime["day"])
	# seperate into both date and time
	var user_time_as_string =\
			str(user_datetime["hour"])+\
			":"+str(user_datetime["minute"])+\
			":"+str(user_datetime["second"])
	
	var datetime_string = user_date_as_string+" "+user_time_as_string
	var user_model_name = OS.get_model_name()
	var user_name = OS.get_name()
	
	var startup_log_string = STARTUP_LOG_FSTRING.format({
			"device": user_name+" "+user_model_name,
			"time": datetime_string
			})
	GlobalLog.info(self, startup_log_string)


func _output_log(arg_next_log: LogRecord) -> void:
	if allow_log_output == false:
		return
	if is_instance_valid(arg_next_log) == false:
		warning(self, "invalid log sent to _output_log from buffer")
		return
	
	var log_code = arg_next_log.log_code_id
	var full_log_string = arg_next_log.full_log_string
	
	if log_code in [CODE.CRITICAL, CODE.ERROR]:
		push_error(full_log_string)
	
	elif log_code == CODE.WARNING:
		push_warning(full_log_string)
	
	# always print
	print(full_log_string)
	# is valid log
	arg_next_log.logged_to_console = true
	total_log_output += 1
	
	# stop program execution after log on critical
	if log_code == CODE.CRITICAL and OS.is_debug_build():
			# if this assertion fires during testing, a critical log has been triggered
			@warning_ignore("assert_always_false")
			assert(2 == 3)


# record LogRecord data to log_register
func _store_log(arg_log: LogRecord) -> void:
	if allow_log_registration == false:
		return
	if is_instance_valid(arg_log) == false:
		warning(self, "invalid log sent to _store_log")
		return
	# structure
	var new_log_register_entry = {
		#"id": arg_log,
		"time": arg_log.timestamp,
		"code": arg_log.log_code_name,
		"output": arg_log.log_message,
	}
	if log_register.has(arg_log.owner):
		log_register[arg_log.owner].append(new_log_register_entry)
	else:
		log_register[arg_log.owner] = [new_log_register_entry]

