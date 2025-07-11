extends Node2D

##############################################################################

# For running specific tests in an export environment

##############################################################################

# var

##############################################################################

# setters/getters

##############################################################################

# virts


func _ready():
	var data_id_register_unpacked := ""
	for i in Data.data_id_register.keys():
		data_id_register_unpacked += "\n{0} -> {1}\n".format([i, Data.data_id_register[i]])
	var schema_register_unpacked := ""
	for i in Data.schema_register.keys():
		schema_register_unpacked += "\n{0} -> {1}\n".format([i, Data.schema_register[i]])
	
	print("===\n{0}:\n{1}\n\n===\n{2}:\n{3}".format([
		"DataIDRegister",
		data_id_register_unpacked,
		"SchemaRegister",
		schema_register_unpacked
	]))


##############################################################################

# public


##############################################################################

# private
