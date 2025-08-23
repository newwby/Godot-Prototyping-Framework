extends PopupPanel

signal panel_closing()
signal panel_opening()

@onready var data_value_container = %DataValueContainer
@onready var data_value_root = %DataValueRoot


func close_panel() -> void:
	pass


func open_panel() -> void:
	pass


func reset_panel() -> void:
	for child in data_value_container.get_children():
		if child == data_value_root:
			continue
		else:
			child.call_deferred("queue_free")


func _on_add_new_pressed():
	if is_instance_valid(data_value_container)\
	and is_instance_valid(data_value_root):
		var new_data_value_item = data_value_root.duplicate()
		new_data_value_item.visible = true
		data_value_container.call_deferred("add_child", new_data_value_item)


func _on_confirm_button_pressed():
	pass


func _on_cancel_button_pressed():
	pass
