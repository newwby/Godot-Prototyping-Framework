# Global_Log

### debug_critical

############################################################################

**Arguments:**
- **arg_caller** (Object)
- **arg_error_message**

**Returns:**
    **void**

### debug_error

**Arguments:**
- **arg_caller** (Object)
- **arg_error_message**

**Returns:**
    **void**

### debug_info

**Arguments:**
- **arg_caller** (Object)
- **arg_error_message**

**Returns:**
    **void**

### debug_warning

debug ('elevated') logs only appear in the debugger/output/console if the object
emitting the log has had their logging permissions elevated
use debug/elevated logs to hide logs you only need when debugging

**Arguments:**
- **arg_caller** (Object)
- **arg_error_message**

**Returns:**
    **void**

### get_permission

**Arguments:**
- **arg_caller** (Object)

**Returns:**
    **bool**

### log_stack_trace

**Arguments:**
- **arg_caller** (Object)

**Returns:**
    **void**

### reset_permission

**Arguments:**
- **arg_caller** (Object)

**Returns:**
    **int**

### store_permission

**Arguments:**
- **arg_caller** (Object)

**Returns:**
    **void**
