DataUtility.gd
==============

DataUtility is a collection of static data management methods.

Constants
---------
- LOCAL_PATH: "res://"
- USER_PATH: "user://"
- BACKUP_SUFFIX: "_backup"
- TEMP_SUFFIX: "_temp"
- EXT_RESOURCE: ".tres"

Public Methods
--------------

clean_file_name(arg_file_name: String) -> String
    Strips invalid characters from a file name, optionally replacing with a passed character.
    
