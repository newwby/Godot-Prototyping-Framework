extends PopupPanel

##############################################################################

# docs

##############################################################################

# variables

signal update_schema(version_id, version_data)

#const VERSION_ID_LABEL_TEXT := "EDITING VERSION {0}"

#//TODO display schema_id alongside version_id, for small windows
#var schema_id := ""

var version_id := "":
	set(value):
		version_id = value
		set_version_id(value)

var version_data := {}

@onready var data_value_container = %DataValueContainer
@onready var data_value_root = %DataValueRoot

@onready var id_invalid_error_warning_label = %ErrorWarning

@onready var confirm_changes_button = %Confirm
#@onready var version_id_label = %VersionID
@onready var version_id_edit_field = %IDEdit

##############################################################################

# public methods


func add_new_data_value(key, value):
	if is_instance_valid(data_value_container)\
	and is_instance_valid(data_value_root):
		var new_data_value_item = data_value_root.duplicate()
		new_data_value_item.visible = true
		new_data_value_item.is_root = false
		new_data_value_item.key_name = str(key)
		new_data_value_item.value_type = typeof(value)
		data_value_container.call_deferred("add_child", new_data_value_item)
		version_data[key] = value
		new_data_value_item.deleted.connect(_on_data_value_deleted)
		new_data_value_item.edited.connect(_on_data_value_edited)
		new_data_value_item.key_changed.connect(_on_data_value_key_changed)


func close_panel(save: bool) -> void:
	if save:
		if is_instance_valid(data_value_container):
			for child in data_value_container.get_children():
				if child == data_value_root:
					continue
				# else
				if "key_name" in child\
				and "value_type" in child:
					# to compare types need to pass back dummy data
					var data = null
					match child.value_type:
						TYPE_STRING:
							data = ""
						TYPE_FLOAT:
							data = 1.0
						TYPE_ARRAY:
							data = []
						TYPE_DICTIONARY:
							data = {}
					if data != null:
						version_data[child.key_name] = data
		update_schema.emit(version_id, version_data)
	
	# clear everything else
	hide()
	reset_panel()
	if is_instance_valid(version_id_edit_field):
		version_id_edit_field.text = ""
	if is_instance_valid(id_invalid_error_warning_label):
		id_invalid_error_warning_label.visible = false
	
	version_id = ""
	version_data = {}


func open_panel(selected_version_id, selected_version_data) -> void:
	version_id = selected_version_id
	if typeof(selected_version_data) == TYPE_DICTIONARY:
		version_data = selected_version_data.duplicate()
		reset_panel()
		var value_data
		for key in selected_version_data.keys():
			value_data = selected_version_data[key]
			add_new_data_value(key, value_data)
	popup_centered()


func reset_panel() -> void:
	for child in data_value_container.get_children():
		if child == data_value_root:
			continue
		else:
			child.call_deferred("queue_free")


func set_version_id(new_version_id: String) -> void:
	if is_instance_valid(version_id_edit_field):
		version_id_edit_field.text = new_version_id
		var is_semantic = Data.is_version_semantic(new_version_id)
		toggle_version_id_error(is_semantic)


func toggle_version_id_error(is_valid: bool) -> void:
	id_invalid_error_warning_label.visible = !is_valid
	confirm_changes_button.disabled = !is_valid


##############################################################################

# private methods


#//TODO this is duplicated from schema_root, could be static func somewhere
# supports fixed value types
# if the data type has changed, insert fake value
#//TODO adjust schema editor to allow custom default values instead of hardcoded
func _get_typed_dummy_data(value_type: int):
	match value_type:
		TYPE_STRING:
			return ""
		TYPE_FLOAT:
			return 1.0
		TYPE_ARRAY:
			return []
		TYPE_DICTIONARY:
			return {}
		_:
			Log.error(self, "_get_typed_dummy_data passed invalid value type")
			return null


func _on_add_new_pressed():
	add_new_data_value("KeyName", "Value")


func _on_confirm_button_pressed():
	close_panel(true)


func _on_cancel_button_pressed():
	close_panel(false)


func _on_data_value_deleted(key_name) -> void:
	if key_name in version_data:
		version_data.erase(key_name)


func _on_data_value_edited(key_name, value_type) -> void:
	if key_name in version_data:
		var new_data = _get_typed_dummy_data(value_type)
		if new_data != null:
			version_data[key_name] = new_data


func _on_data_value_key_changed(old_key, new_key) -> void:
	print("changing {0} -> {1}".format([old_key, new_key]))
	var has_changed := false
	if old_key == new_key:
		return
	if old_key in version_data:
		var value = version_data[old_key]
		if new_key != null:
			version_data[new_key] = value
			has_changed = true
	if has_changed:
		version_data.erase(old_key)


func _on_id_edit_text_changed(new_text):
	var is_semantic = Data.is_version_semantic(new_text)
	toggle_version_id_error(is_semantic)
	if is_semantic:
		version_id = new_text
