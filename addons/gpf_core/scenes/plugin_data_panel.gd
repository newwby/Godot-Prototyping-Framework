@tool
extends Control

#####################################################################

const DB_FIELD_MIN_WIDTH := 50

var tree_root: TreeItem

@onready var tree = $Tree

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

#//DESIGN NOTES
# schema id & version does not need to be displayed
# schema id/version can be changed in schema editor
# schema editor creates schema, the id/version are treated as same but id determines where it is saved
# author, package, id should not be changeable in editor or can't find the record to update
#	-- unless we have a secret id value when loaded to compare against? hashed data of all values

# type editable
# tags dropdown with delete/add button for new tags
# data depends on the data type
#	most = text, but with data validation
#	array with values = CELL_MODE_RANGE

#func _on_tree_item_edited(item: TreeItem, column: int, new_text: String) -> void:
func _on_tree_item_edited() -> void:
	var edited_item: TreeItem = tree.get_edited()
	var edited_col = tree.get_edited_column()
	var new_text = edited_item.get_text(edited_col)
	print("{0} - {1} - {2}".format([edited_item, edited_col, new_text]))
	for i in tree.columns:
		print(edited_item.get_text(i))


#func _old_ready() -> void:
	#var root = tree.create_item()
	## ► 4. One TreeItem per record.
	#for rec in records:
		#var row = tree.create_item(root)
		#for col_i in cols.size():
			#var key = cols[col_i]
			#var value = null
			#match key:
				#"data.name":
					#value = rec.data.get("name", "")
				#"data.cost":
					#value = rec.data.get("cost", "")
				#"data.damage":
					#value = rec.data.get("damage", "")
				#"data.range":
					#value = rec.data.get("range", "")
				#_ :
					#value = rec.get(key, "")
			#row.set_text(col_i, str(value))
			#row.set_editable(col_i, true)         # make cell writable if you want
#
	## ► 5. (Optional) update the underlying dictionary when the user edits a cell.
	#tree.item_edited.connect(_on_tree_item_edited)
#
#func _on_tree_item_edited(item: TreeItem, column: int, new_text: String) -> void:
	#var row_index = item.get_index()            # index inside root
	#var key       = cols[column]
	#var rec       = records[row_index]
	#match key:
		#"data.name":   rec.data["name"]   = new_text
		#"data.cost":   rec.data["cost"]   = float(new_text)
		#"data.damage": rec.data["damage"] = float(new_text)
		#"data.range":  rec.data["range"]  = float(new_text)
		#_: rec[key] = new_text


##############################################################################

# public methods

##############################################################################

# private methods


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		print("hello I'm visible")
	else:
		print("data panel hidden")
