extends PopupPanel

signal panel_closing()
signal panel_opening()

@onready var data_value_container = %DataValueContainer
@onready var data_value_root = %DataValueRoot


func close_panel() -> void:
	pass


func open_panel(selected_version_data) -> void:
	print("open ", selected_version_data)
	if typeof(selected_version_data) == TYPE_DICTIONARY:
		reset_panel()
		#add_new_data_value()
		#print(version_data)
		var value_data
		for key in selected_version_data.keys():
			value_data = selected_version_data[key]
			print("{0}: {1}".format([key, typeof(value_data)]))
			add_new_data_value(key, value_data)
	popup_centered()


func reset_panel() -> void:
	for child in data_value_container.get_children():
		if child == data_value_root:
			continue
		else:
			child.call_deferred("queue_free")

func add_new_data_value(key, value):
	if is_instance_valid(data_value_container)\
	and is_instance_valid(data_value_root):
		var new_data_value_item = data_value_root.duplicate()
		new_data_value_item.visible = true
		new_data_value_item.is_root = false
		new_data_value_item.key_name = str(key)
		new_data_value_item.value_type = typeof(value)
		data_value_container.call_deferred("add_child", new_data_value_item)


func _on_add_new_pressed():
	add_new_data_value("KeyName", 0)


func _on_confirm_button_pressed():
	pass


func _on_cancel_button_pressed():
	pass
