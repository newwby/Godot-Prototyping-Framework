extends MarginContainer

@onready var data_panel = %DataPanel
@onready var schema_panel = %SchemaPanel

func _on_show_data_pressed():
	if is_instance_valid(data_panel):
		data_panel.visible = true
	if is_instance_valid(schema_panel):
		schema_panel.visible = false


func _on_show_schema_pressed():
	if is_instance_valid(data_panel):
		data_panel.visible = false
	if is_instance_valid(schema_panel):
		schema_panel.visible = true
