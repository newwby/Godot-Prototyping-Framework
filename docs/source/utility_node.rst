NodeUtility.gd
==============

NodeUtility is a collection of static object management methods.

Public Methods
--------------

confirm_connection(arg_subject_signal: Signal, arg_target_method: Callable, arg_binds: Array = []) -> bool
    Verifies that a connection exists before attempting to connect. 
    Returns true if the connection exists or is successfully created, false otherwise.

is_valid_in_tree(arg_object) -> bool
    Checks if a node exists, hasn't been deleted, and is inside the scene tree. 
    Returns false if not passed a valid object or node not inside the scene tree. 
    Returns true if passed a valid node inside the scene tree.
