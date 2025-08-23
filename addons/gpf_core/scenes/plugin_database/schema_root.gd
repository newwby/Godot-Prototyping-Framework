extends MarginContainer

@onready var schema_editing_panel = %SchemaEditingPanel

func _on_create_new_pressed():
	pass # Replace with function body.


func _on_delete_all_pressed():
	pass # Replace with function body.


func _on_add_version_pressed():
	if is_instance_valid(schema_editing_panel):
		schema_editing_panel.popup_centered()


func _on_edit_version_pressed():
	pass # Replace with function body.


func _on_delete_version_pressed():
	pass # Replace with function body.
