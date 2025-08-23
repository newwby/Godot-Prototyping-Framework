extends HBoxContainer

# if is_root container cannot be deleted
@export var is_root: bool = false

@onready var delete_button = %Delete

func _on_delete_pressed():
	if is_root:
		if is_instance_valid(delete_button):
			delete_button.visible = false
		return
	self.call_deferred("queue_free")
