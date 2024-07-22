# meta-name: Style Guide
# meta-description: Provides commented out structure adhering to Godot style guide
# meta-default: true
# meta-space-indent: 4

#class_name class_name_placeholder
extends _BASE_

#01. tool
#02. class_name
#03. extends

##############################################################################

# This is a slightly modiffied version of the Godot style guide
# See the full style guide at:
#	https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html

# GPF STYLE SUGGESTIONS
# all arguments should be prefixed with arg_ so it is clear where arguments
#	are used in the method block versus variants declared in the block
#	 func _example(arg_argument):
#		var new_variant
#		do_stuff(new_variant)
#		do_stuff(arg_argument)

##############################################################################

#04. # dependencies, docstring

##############################################################################

#05. signals
#06. enums
#07. constants
#
#08. exported variables
#09. public variables
#10. private variables
#11. onready variables

##############################################################################

# setters/getters

##############################################################################

# constructor

##############################################################################

# virtual methods


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'arg_delta' is the elapsed time since the previous frame.
#func _process(arg_delta):
#	pass


##############################################################################

# public methods


#func example_method():
#	pass


##############################################################################

# private methods


#func _example_method():
#	pass

