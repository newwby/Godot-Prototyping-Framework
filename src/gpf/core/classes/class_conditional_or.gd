extends ConditionalAnd

class_name ConditionalOr

##############################################################################

# An extended version of the conditional class (base ConditionalAnd) which
#	replaces the 'and' evaluation with 'Or'

##############################################################################

# variants

##############################################################################

# constructor


func _init(
		arg_default_outcome: bool,
		arg_include_base_value: bool = false).\
		(arg_default_outcome, arg_include_base_value): # pass to parent
	pass


##############################################################################

# virt


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################

# public


##############################################################################

# private


# shadowed in extended versions
func _calculate_condition(
		arg_current_outcome: bool,
		arg_conditional_value: bool
		) -> bool:
	return arg_current_outcome or arg_conditional_value

