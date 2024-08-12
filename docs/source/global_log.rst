GlobalLog API Documentation
===========================

Overview
--------
`GlobalLog` is a logging utility for the Godot Engine, designed to facilitate logging with different severity levels and permissions. It supports critical, error, warning, and info logs. The logs can be output to the console and registered for later retrieval.

Enumerations
------------
**CODE**: Defines the type of logs:
- `UNDEFINED` (0)
- `CRITICAL` (1)
- `ERROR` (2)
- `WARNING` (3)
- `INFO` (4)

Constants
---------
- **STARTUP_LOG_FSTRING**: Format string for the initial log message when the logger starts.
  - Example: `"[{device}] Logger service ready @ {time}"`
- **LOG_FSTRING**: Format string for log messages.
  - Example: `"[t{time}] {caller}\t[{type}] | {message}"`

Variables
---------
- **record_logs**: Determines if logs should be recorded.
  - Type: `bool`
  - Default: `true`
- **allow_log_output**: Allows logs to be printed to the console/log file.
  - Type: `bool`
  - Default: `true`
- **allow_log_registration**: Allows logs to be saved.
  - Type: `bool`
  - Default: `true`
- **total_log_calls**: Total logs registered this runtime.
  - Type: `int`
- **total_log_output**: Total logs output to the console.
  - Type: `int`
- **log_register**: Record of who logged what and when.
  - Type: `Dictionary`
- **log_permissions**: Manages permissions for logging on a per-script basis.
  - Type: `Dictionary`
- **_log_permissions_last_state**: Stores last log permission state.
  - Type: `Dictionary`

Classes
-------
### LogRecord
Represents a single log entry.

**Properties**:
- `owner`: The object that created the log.
  - Type: `Object`
- `timestamp`: Time of the log entry.
  - Type: `int`
- `log_code_id`: ID of the log type.
  - Type: `int`
- `log_code_name`: Name of the log type.
  - Type: `String`
- `log_message`: The log message.
  - Type: `String`
- `logged_to_console`: Whether the log was output to the console.
  - Type: `bool`
  - Default: `false`
- `full_log_string`: The formatted log message.
  - Type: `String`

**Methods**:
- `__init__(arg_owner, arg_log_timestamp, arg_log_code_id, arg_log_code_name, arg_log_message, arg_log_string)`
  - Initializes a LogRecord instance.
  - **Parameters**:
    - `arg_owner`: Object - The object that created the log.
    - `arg_log_timestamp`: int - Time of the log entry.
    - `arg_log_code_id`: int - ID of the log type.
    - `arg_log_code_name`: String - Name of the log type.
    - `arg_log_message`: String - The log message.
    - `arg_log_string`: String - The formatted log message.

Methods
-------
### Public Methods

- **critical(arg_caller, arg_error_message, arg_show_on_elevated_only=false)**
  - Logs a critical error. Stops program execution in debug mode.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.
    - `arg_show_on_elevated_only`: bool - Whether to show only if permissions are elevated (default: `false`).

- **debug_critical(arg_caller, arg_error_message)**
  - Logs a critical error only if the caller has elevated permissions.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.

- **debug_error(arg_caller, arg_error_message)**
  - Logs an error only if the caller has elevated permissions.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.

- **debug_info(arg_caller, arg_error_message)**
  - Logs info only if the caller has elevated permissions.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.

- **debug_warning(arg_caller, arg_error_message)**
  - Logs a warning only if the caller has elevated permissions.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.

- **error(arg_caller, arg_error_message, arg_show_on_elevated_only=false)**
  - Logs an error.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.
    - `arg_show_on_elevated_only`: bool - Whether to show only if permissions are elevated (default: `false`).

- **info(arg_caller, arg_error_message, arg_show_on_elevated_only=false)**
  - Logs information.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.
    - `arg_show_on_elevated_only`: bool - Whether to show only if permissions are elevated (default: `false`).

- **log_stack_trace(arg_caller)**
  - Logs the stack trace if in debug mode.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.

- **warning(arg_caller, arg_error_message, arg_show_on_elevated_only=false)**
  - Logs a warning.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_error_message`: Variant - The error message.
    - `arg_show_on_elevated_only`: bool - Whether to show only if permissions are elevated (default: `false`).

- **get_permission(arg_caller)**
  - Returns the logging permission of the caller.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
  - **Returns**: `bool` - The permission state of the caller.

- **reset_permission(arg_caller)**
  - Resets the logging permission of the caller to the last stored state.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
  - **Returns**: `int` - OK if successful, ERR_INVALID_PARAMETER otherwise.

- **set_permission_default(arg_caller, arg_store_permission=false)**
  - Sets the caller's logging permission to default.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_store_permission`: bool - Whether to store the current permission before changing (default: `false`).

- **set_permission_disabled(arg_caller, arg_store_permission=false)**
  - Disables logging permission for the caller.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_store_permission`: bool - Whether to store the current permission before changing (default: `false`).

- **set_permission_elevated(arg_caller, arg_store_permission=false)**
  - Elevates logging permission for the caller.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
    - `arg_store_permission`: bool - Whether to store the current permission before changing (default: `false`).

- **store_permission(arg_caller)**
  - Stores the current logging permission of the caller.
  - **Parameters**:
    - `arg_caller`: Object - The caller object.
