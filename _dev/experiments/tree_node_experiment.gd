extends Control

func _ready() -> void:
	pass
	#var all_data := Data.data_collection
	#for i in all_data:
		#print(i)
	
	var tree = Tree.new()
	var root = tree.create_item()
	tree.hide_root = true
	var child1 = tree.create_item(root)
	var child2 = tree.create_item(root)
	var subchild1 = tree.create_item(child1)
	subchild1.set_text(0, "Subchild1")
	self.call_deferred("add_child", tree)
