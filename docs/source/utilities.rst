============
Utility Scripts
============

Various classes with public static methods for a singular purpose.

DataUtility
************

DataUtility is collection of static data management methods

clean_file_name
~~~~~~~~~~

 strips invalid characters from a file name, optionally replacing with a passed
	character; can also replace spaces with the same character if desired
 converts given file name to lower case
 on return warns if still invalid
 most importantly provdies options for how to handle spaces/case
 cleans file names for Windows OS

get_dir_names_recursive
~~~~~~~~~~

returns names of all directories within a path (recursively)

get_dir_paths
~~~~~~~~~~

method returns paths for every directory inside a directory path
 can search recursively (default behaviour), returning all nested directories

get_file_names
~~~~~~~~~~

clone of get_file_paths that only returns the names of any files found
 if arg_is_recursive is set false will only search the exact directory given

get_file_paths
~~~~~~~~~~

Fetches the file path for every file in a directory (recursively by default)
 if arg_is_recursive is set false will only search the exact directory given

save_resource
~~~~~~~~~~

method to save any resource or resource-extended custom class to disk.
 call this method with 'if save_resource(*args) == OK' to validate
 if called on a non-existing file or path it will write the entire path

validate_directory
~~~~~~~~~~

creates directory at path if it doesn't exist

NodeUtility
************
NodeUtility is collection of static object management methods

confirm_connection
~~~~~~~~~~

verifies that a connection exists before attempting to connect
 if connection already exists, return true
 if connection does not exist, create it and return true if successful
 if connection does not exist and cannot be created, return false

is_valid_in_tree
~~~~~~~~~~

check if node exists/hasn't been deleted, and is inside scene tree
 will return false if not passed an object, if passed a node not inside
	the scene tree, or if passed an object that has been freed
 will only return true if passed a valid node inside the scene tree

SortUtility
************
SortUtility is collection of static array sorting methods

sort_ascending
~~~~~~~~~~

sort_descending
~~~~~~~~~~

