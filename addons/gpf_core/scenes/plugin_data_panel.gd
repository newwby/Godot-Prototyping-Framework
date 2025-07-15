@tool
extends Control

#####################################################################

const DB_FIELD_MIN_WIDTH := 50

var tree_root: TreeItem

@onready var tree = $Scroll/VBox/Tree

#####################################################################

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_setup_tree()
	_populate_database()


func _setup_tree() -> void:
	tree_root = tree.create_item()
	tree.hide_root = true
	#TreeViewColumn 
	var columns := Data.EXPECTED_DATA_STRUCTURE.keys()
	tree.columns = columns.size()
	for i in range(columns.size()):
		tree.set_column_title(i, columns[i])
		tree.set_column_expand(i, false)
		tree.set_column_custom_minimum_width(i, DB_FIELD_MIN_WIDTH)
		tree.set_column_expand(i, true)
	
	# show tree headers
	var header_row = tree.create_item(tree_root)
	for i in range(columns.size()):
		header_row.set_text(i, columns[i])
		header_row.set_editable(i, false)
	
	tree.item_edited.connect(_on_tree_item_edited)
	

func _populate_database() -> void:
	for item in Data.data_collection:
		if typeof(item) == TYPE_DICTIONARY:
			_populate_record(item)


# record is validated if it's from global Data registers
# adds record to the database view
func _populate_record(arg_data: Dictionary) -> void:
	var columns := Data.EXPECTED_DATA_STRUCTURE.keys()
	var row = tree.create_item(tree_root)
	for i in range(columns.size()):
		var key = columns[i]
		var value = arg_data.get(key, "")
		row.set_text(i, str(value))
		row.set_editable(i, true)
		row.set_autowrap_mode(i, TextServer.AUTOWRAP_WORD_SMART)


func _on_tree_item_edited() -> void:
	var edited_item: TreeItem = tree.get_edited()
	var edited_col = tree.get_edited_column()
	var new_text = edited_item.get_text(edited_col)
	print("{0} - {1} - {2}".format([edited_item, edited_col, new_text]))
	for i in tree.columns:
		print(edited_item.get_text(i))


##############################################################################

# public methods

##############################################################################

# private methods


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		pass
