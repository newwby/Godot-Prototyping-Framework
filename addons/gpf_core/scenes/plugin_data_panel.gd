@tool
extends Control

##############################################################################

#04. # dependencies, docstring

##############################################################################

# signals, enums, constants
# exported, public, private, onready

@onready var tree: Tree = $Tree

##############################################################################

# setters/getters

##############################################################################

# constructor & virtuals

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

##############################################################################

# public methods

##############################################################################

# private methods


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		print("hello I'm visible")
	else:
		print("data panel hidden")
