@tool
extends PopupPanel

signal id_changed(author, package, name)

@onready var author_edit = %AuthorEdit
@onready var package_edit = %PackageEdit
@onready var name_edit = %NameEdit

@onready var confirm_button = %Confirm
@onready var cancel_button = %Cancel


func open_panel(author_text: String, package_text: String, name_text: String):
	if is_instance_valid(author_edit):
		author_edit.text = author_text
	if is_instance_valid(package_edit):
		package_edit.text = package_text
	if is_instance_valid(name_edit):
		name_edit.text = name_text
	popup_centered()


func _on_confirm_button_pressed():
	var author_text = ""
	var package_text = ""
	var name_text = ""
	
	if is_instance_valid(author_edit):
		author_text = author_edit.text
	if is_instance_valid(package_edit):
		package_text = package_edit.text
	if is_instance_valid(name_edit):
		name_text = name_edit.text
	
	hide()
	id_changed.emit(author_text, package_text, name_text)


func _on_cancel_button_pressed():
	hide()
