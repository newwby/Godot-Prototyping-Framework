============
GlobalLog
============

Autoload part of the core module

Members
***********

Variants

LogRecord
***********

Internal class

Logging Methods
***********

Default logging methods to call with GlobalLog.methodname

*critical*
~~~~~~~~~~

Crashes game in debug mode if triggered (with a log message)

*error*
~~~~~~~~~~

Raises error and logs

*info*
~~~~~~~~~~

Logs to console

*warning*
~~~~~~~~~~

Raises warning and logs

Elevated Logging Methods
***********

Logging methods that only trigger if elevated permissions are set on the caller. If an invalid/null caller is specified the log can never be elevated.

debug_critical
~~~~~~~~~~

As critical but elevated permissions only (otherwise doesn't log).

debug_error
~~~~~~~~~~

As error but elevated permissions only (otherwise doesn't log).

debug_info
~~~~~~~~~~

As info but elevated permissions only (otherwise doesn't log).

debug_warning
~~~~~~~~~~

As warning but elevated permissions only (otherwise doesn't log).

Permission Handling Methods
***********

Methods that handle elevated permissions for log callers.

get_permission
~~~~~~~~~~

Checks the current permission state (returns a permission enum value equalling an int)

reset_permission
~~~~~~~~~~

Resets the target to permission stored with 'reset permission'

set_permission_default
~~~~~~~~~~

Resets the target to default permission state (no changed permission; regular logs only, elevated logs do not show up)

set_permission_disabled
~~~~~~~~~~

Resets the target to banned permission state (all logs disabled)

set_permission_elevated
~~~~~~~~~~

Resets the target to elevated permission state (all, including elevated, logs show up)

store_permission
~~~~~~~~~~

Tells target to remember permission state.

