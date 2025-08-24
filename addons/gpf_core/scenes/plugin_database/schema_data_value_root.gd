extends HBoxContainer

##############################################################################

# docs

##############################################################################

# variables

# if is_root container cannot be deleted
@export var is_root: bool = false

# mapping variant type to value field item indexes
const ALLOWED_VALUE_TYPES := {
	TYPE_STRING: 0,
	TYPE_FLOAT: 1,
	TYPE_ARRAY: 2,
	TYPE_DICTIONARY: 3
}

var key_name: String = "KeyName":
	set(value):
		key_name = value
		set_key_field()

var value_type: int = 0:
	set(value):
		value_type = value
		set_value_field()

@onready var key_field = %Key
@onready var value_field = %Value
@onready var delete_button = %Delete

##############################################################################

# virtual methods


func _ready():
	set_key_field()
	set_value_field()


##############################################################################

# public methods


func set_key_field() -> void:
	if is_instance_valid(key_field):
		key_field.text = key_name


func set_value_field() -> void:
	if is_instance_valid(value_field):
		var index = ALLOWED_VALUE_TYPES.get(value_type, -1)
		if index == -1:
			Log.warning(self, "value type {0} is invalid (key {1})".format([value_type, key_name]))
		value_field.select(index)


##############################################################################

# private methods


func _on_delete_pressed():
	if is_root:
		if is_instance_valid(delete_button):
			delete_button.visible = false
		return
	self.call_deferred("queue_free")
