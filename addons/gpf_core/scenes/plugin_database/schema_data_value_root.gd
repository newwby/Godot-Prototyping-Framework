extends HBoxContainer

##############################################################################

# docs

##############################################################################

# variables

signal deleted(key)
signal edited(key, value)
signal key_changed(old_key, new_key)

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
		var old_value = key_name
		key_name = value
		set_key_field()
		key_changed.emit(old_value, value)

var value_type: int = 0:
	set(value):
		value_type = value
		set_value_field()
		edited.emit(key_name, value_type)

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


#//TODO need to implement value migration if a key field name changes without type change
func set_key_field() -> void:
	if is_instance_valid(key_field):
		if key_field.text != key_name:
			key_field.text = key_name


func set_value_field() -> void:
	# root is skipped as value always null
	if is_root:
		return
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
	deleted.emit(key_name)
	self.call_deferred("queue_free")


func _on_value_item_selected(index):
	value_type = ALLOWED_VALUE_TYPES.find_key(index)


func _on_key_text_changed(new_text):
	key_name = new_text
	#if is_instance_valid(key_field):
		#key_field.
