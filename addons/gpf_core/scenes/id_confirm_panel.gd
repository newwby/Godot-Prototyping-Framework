extends PopupPanel

@onready var author_edit = %AuthorEdit
@onready var package_edit = %PackageEdit
@onready var name_edit = %NameEdit


func open_panel(author_text: String, package_text: String, name_text: String):
	if is_instance_valid(author_edit):
		author_edit.text = author_text
	if is_instance_valid(package_edit):
		package_edit.text = package_text
	if is_instance_valid(name_edit):
		name_edit.text = name_text
	popup_centered()
