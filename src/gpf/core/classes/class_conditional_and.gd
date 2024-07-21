extends RefCounted

class_name ConditionalAnd

##############################################################################

# Complex bools that allow setting multiple bool values without interfering
#	with each other; e.g. allowed_to_move could be set false by an animator
#	and a status effect, but still remain false after the effect clears

# Conditionals default to true but evaluate false if even one false is present

# Any change evaluates whether the output would have changed, and emits
# a signal if it has.

##############################################################################

# signals emitted if the state changes after an add or remove call
signal outcome_changed()
signal outcome_checked()
signal is_true()
signal is_false()

# the initial value of the conditional, what it should return if no condition
#	has been applied
var default_outcome := true: set = set_default_outcome

var _conditions := {}
# the outcome of the conditional - is only recalculated when a key is
# added, removed, or changed
var _current_outcome := default_outcome

# by default conditionals ignore their default outcome once a condition is
#	added, but you can specify that they include their default outcome in
#	their evaluation by setting this to true on initialisation
# (if used carelessly this can produce conditionals that always evaluate
#	true or always evaluate false, regardless of condition)
# if you're unsure whether to set this value, leave it as the default and check
#	out the UnitTests for ConditionalAnd to see how including the base value
#	 affects the evaluation result
var _include_base_value := false

##############################################################################

# constructor


func _init(arg_default_outcome: bool, arg_include_base_value: bool = false):
	self.default_outcome = arg_default_outcome
	self._include_base_value = arg_include_base_value
	_update_current_outcome()


##############################################################################

# setters/getters


func set_default_outcome(arg_value: bool) -> void:
	default_outcome = arg_value
	_update_current_outcome()


##############################################################################

# public


# assign new conditional value or overwrite an existing one
func add(arg_key, arg_value: bool) -> void:
	_conditions[arg_key] = arg_value
	_update_current_outcome()


func get_all_conditions() -> Dictionary:
	return _conditions


func get_condition(arg_key):
	if _conditions.has(arg_key):
		return _conditions[arg_key]
	else:
		return null


func has_condition(arg_key) -> bool:
	return _conditions.has(arg_key)


# getter
func evaluate() -> bool:
	return _current_outcome


# Returns true if the given key was present, false otherwise.
func remove(arg_key) -> bool:
	var has_changed: bool = _conditions.erase(arg_key)
	_update_current_outcome()
	return has_changed


##############################################################################

# private


# shadowed in extended versions
func _calculate_condition(
		arg_current_outcome: bool,
		arg_conditional_value: bool
		) -> bool:
	return arg_current_outcome and arg_conditional_value


# does nothing if output state is still the same
func _check_state_change(
		arg_previous_state: bool,
		arg_current_state: bool) -> void:
	emit_signal("outcome_checked")
	if arg_previous_state != arg_current_state:
		emit_signal("outcome_changed")
		if arg_current_state == true:
			emit_signal("is_true")
		else:
			emit_signal("is_false")


# checks the conditional state and emits conditional state changed signals
func _update_current_outcome() -> void:
	var start_state = evaluate()
	var outcome = null
	var all_values: Array = _conditions.values()
	if _include_base_value:
		all_values.append(default_outcome)
	for conditional_value in all_values:
		if typeof(conditional_value) == TYPE_BOOL:
			if outcome == null:
				outcome = conditional_value
			else:
				outcome = _calculate_condition(outcome, conditional_value)
	if typeof(outcome) == TYPE_BOOL:
		_current_outcome = outcome
	else:
		_current_outcome = default_outcome
	_check_state_change(start_state, evaluate())

