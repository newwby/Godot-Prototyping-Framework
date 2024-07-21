extends Resource

class_name Definition

##############################################################################

# Definition files are data holders that can be used by ModDefMgr to pass
#	properties to a DefManager.
# Definitions provide a unified class for all definitions to extend
#	from (setting their own class names is unnecessary)

##############################################################################

# this property is so the DefManager can validate the Definition is
#	intended for that particular DefManager
# devs, if extending the Definition class set the def_id in _init()
@export var def_id := ""

# property_name : property_value
# key/value pair to map properties to a new definition object
# properties are assigned with the set method, and as such if the property
#	name does not exist or the given value's type doesn't match, nothing
#	will happen.
# devs, if extending the Definition class set def_properties in _init()
@export var def_properties: Dictionary = {}

@export var definition_subject: Script = null

##############################################################################


# example init for extended definitions
# devs note that assigning values in init will overwrite resource modified
#	properties, and should only be done if extending the definition class
#	to add new functionality or shadow methods from the base definition class 
#func _init():
#	self.def_id = ""
	# if property_name isn't found, property_value won't be assigned
#	self.def_properties = {
#		"property_name": "property_value",
#	}


##############################################################################


func assign_properties(arg_target: Object) -> void:
	# error logging will happen in is_assign_valid
	if is_assign_valid(arg_target):
		GlobalFunc.multiset_properties(arg_target, def_properties)


# confirm if assign_properties can be called on the target object without failing
func is_assign_valid(arg_target: Object):
	if def_properties.is_empty():
		GlobalLog.warning(self, "{0}.assign_properties called on {1} with empty def_properties".format([def_id, arg_target]))
		return false
	if definition_subject == null:
		GlobalLog.warning(self, "{0}.assign_properties called on {1} without specifying definition_subject".format([def_id, arg_target]))
		return false
	if arg_target.get_script() == definition_subject:
		return true
	else:
		GlobalLog.error(self, "{0}.assign_properties called on {1}, returned invalid subject type error".format([def_id, arg_target]))
		return false

