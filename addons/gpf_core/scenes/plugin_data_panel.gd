@tool
extends Control

#####################################################################

const DB_FIELD_MIN_WIDTH := 50

var tree_root: TreeItem

# main database
@onready var database_tree = %DatabaseTree

# filter controls
@onready var filter_schema_id = %FilterSchemaID
@onready var filter_schema_version = %FilterSchemaVersion

#####################################################################

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_setup_tree()
	_populate_filters()
	_select_schema()


func _setup_tree() -> void:
	database_tree.clear()
	tree_root = database_tree.create_item()
	database_tree.hide_root = true
	database_tree.item_edited.connect(_on_tree_item_edited)
	
	var columns := Data.EXPECTED_DATA_STRUCTURE.keys()
	database_tree.columns = columns.size()
	
	#var header_row = database_tree.create_item(tree_root)
	
	for i in range(columns.size()):
		database_tree.set_column_title(i, columns[i])
		database_tree.set_column_expand(i, false)
		database_tree.set_column_custom_minimum_width(i, DB_FIELD_MIN_WIDTH)
		database_tree.set_column_expand(i, true)
		
		# set initial row
		#header_row.set_text(i, columns[i])
		#header_row.set_editable(i, false)
		#header_row.set_custom_bg_color(i, Color.DIM_GRAY)
		#header_row.set_selectable(i, false)


#//TODO move _setup tree behaviour into here for schema 
func _clear_database() -> void:
	var child := tree_root.get_first_child()
	while child:
		var next = child.get_next()
		child.call_deferred("free")
		child = next

func _populate_database() -> void:
	#tree_root.c
	for item in Data.data_collection:
		if typeof(item) == TYPE_DICTIONARY:
			_populate_record(item)


# temp checker for _populate_record to check if schema id/version matches
# actually need to add GlobalData filtering method to save iterating over everything
func _temp_validate_item(arg_record: Dictionary) -> bool:
	var schema_id = arg_record.get("schema_id", null)
	var schema_ver = arg_record.get("schema_version", null)
	if schema_id == get_selected_schema_id()\
	and schema_ver == get_selected_schema_version():
		return true
	# else
	return false

# record is validated if it's from global Data registers
# adds record to the database view
func _populate_record(arg_data: Dictionary) -> void:
	if _temp_validate_item(arg_data) == false:
		return
	var columns := Data.EXPECTED_DATA_STRUCTURE.keys()
	var row = database_tree.create_item(tree_root)
	for i in range(columns.size()):
		var key = columns[i]
		var value = arg_data.get(key, "")
		row.set_text(i, str(value))
		row.set_editable(i, true)
		row.set_autowrap_mode(i, TextServer.AUTOWRAP_WORD_SMART)
		row.set_tooltip_text(i, "")
		#row.set_tooltip_text(i, columns[i])


func _on_tree_item_edited() -> void:
	var edited_item: TreeItem = database_tree.get_edited()
	var edited_col = database_tree.get_edited_column()
	var new_text = edited_item.get_text(edited_col)
	print("{0} - {1} - {2}".format([edited_item, edited_col, new_text]))
	for i in database_tree.columns:
		print(edited_item.get_text(i))


##############################################################################

# public methods

##############################################################################

# private methods


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		pass


func _populate_filters() -> void:
	filter_schema_id.clear()
	for schema_id in Data.schema_register.keys():
		filter_schema_id.add_item(schema_id)


func get_selected_schema_id() -> String:
	var schema_id_idx = filter_schema_id.selected
	var schema_id_text = filter_schema_id.get_item_text(schema_id_idx)
	return schema_id_text


func get_selected_schema_version() -> String:
	var schema_ver_idx = filter_schema_version.selected
	var schema_ver_text = filter_schema_version.get_item_text(schema_ver_idx)
	return schema_ver_text


# when schema id is changed in the dropdown control
#	update the schema versions
#	default to the highest version
func _on_filter_schema_id_item_selected(index):
	#print(filter_schema_id.selected, " - {0}".format([filter_schema_id.get_item_text(filter_schema_id.selected)]))
	var schema_id_text = get_selected_schema_id()
	var schema_versions = Data.schema_register.get(schema_id_text, [])
	
	# setup the version dropdown
	filter_schema_version.clear()
	for i in schema_versions:
		filter_schema_version.add_item(i)
	# default to most recent version
	var idx = filter_schema_version.item_count-1
	#filter_schema_version.select(idx)
	_on_filter_schema_version_item_selected(idx)


# when schema version is changed update the data
func _on_filter_schema_version_item_selected(index):
	#print(filter_schema_version.selected, " - {0}".format([filter_schema_version.get_item_text(filter_schema_version.selected)]))
	# temp handling - clearing the entire tree is a bit messy
	_clear_database()
	_populate_database()


func _select_schema():
	_on_filter_schema_id_item_selected(filter_schema_id.selected)
	_on_filter_schema_version_item_selected(filter_schema_version.selected)
