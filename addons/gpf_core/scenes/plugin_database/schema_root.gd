extends MarginContainer

##############################################################################

# docs

##############################################################################

# variables

const DB_FIELD_MIN_WIDTH := 50.0

var tree_root: TreeItem

# data entry paths are indexed by the tree item displaying their value
# {TreeItem: String}
#//TODO need to add path indexing to globalData for schemaFiles
var uid_map := {}

# keys() includes versions
var active_version_list := {}

# column headers
var tree_columns := []

@onready var database_tree = %SchemaDBTree
@onready var schema_editing_panel = %SchemaEditingPanel
@onready var filter_schema_id = %FilterSchemaID

##############################################################################

# virtual methods


func _ready():
	_initial_tree_setup()
	select_schema_id(Data.schema_register.keys().get(0))


##############################################################################

# public methods


func select_schema_id(schema_id_name):
	active_version_list = Data.schema_register.get(schema_id_name)
	if typeof(active_version_list) == TYPE_DICTIONARY:
		_reload_database()
	else:
		active_version_list = {}
		Log.error(self, "select_schema_id type error")


##############################################################################

# private methods


# delete all tree items
func _clear_tree() -> void:
	uid_map.clear()
	var child := tree_root.get_first_child()
	while child:
		var next = child.get_next()
		child.call_deferred("free")
		child = next


func _initial_tree_setup() -> void:
	database_tree.clear()
	database_tree.hide_root = true
	#database_tree.item_edited.connect(_on_tree_item_edited)
	#database_tree.item_selected.connect(_on_tree_item_selected)
	tree_root = database_tree.create_item()
	
	if is_instance_valid(filter_schema_id):
		for schema_id in Data.schema_register.keys():
			filter_schema_id.add_item(schema_id)


func _load_data_list() -> void:
	for version in active_version_list.keys():
		_load_version_item(version)


func _load_version_item(version_key) -> void:
	var version_data = active_version_list.get(version_key)
	if typeof(version_data) != TYPE_DICTIONARY:
		Log.error(self, "type error in _load_version_item")
		return
	#var new_tree_item := TreeItem
	#tree_root.add_child(new_tree_item)
	var new_row: TreeItem = database_tree.create_item(tree_root)
	if new_row == null:
		return
	
	# schema version key
	new_row.set_text(0, str(version_key))
	# schema data values
	new_row.set_text(1, str(version_data.keys()))
	# both
	for idx in range(2):
		new_row.set_autowrap_mode(idx, TextServer.AUTOWRAP_WORD_SMART)
		new_row.set_tooltip_text(idx, "")
		new_row.set_editable(idx, false)
	
	#//TODO update path/uid_map


func _load_tree_structure() -> void:
	# refresh the tree root
	_clear_tree()
	# tree needs to list all versions
	
	tree_columns = ["version", "values"]
	database_tree.columns = tree_columns.size()
	
	for i in range(tree_columns.size()):
		database_tree.set_column_title(i, tree_columns[i])
		database_tree.set_column_custom_minimum_width(i, DB_FIELD_MIN_WIDTH)
		database_tree.set_column_expand(i, true)
		database_tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)


func _on_add_version_pressed():
	if is_instance_valid(schema_editing_panel):
		schema_editing_panel.popup_centered()


func _on_create_new_pressed():
	pass # Replace with function body.


func _on_delete_all_pressed():
	pass # Replace with function body.


func _on_delete_version_pressed():
	pass # Replace with function body.


func _on_edit_version_pressed():
	pass # Replace with function body.


# when the schema ID is changed
func _on_filter_schema_id_item_selected(index):
	if is_instance_valid(filter_schema_id):
		var schema_id_name = filter_schema_id.get_item_text(index)
		select_schema_id(schema_id_name)


func _reload_database() -> void:
	_load_tree_structure()
	_load_data_list()
	call_deferred("_select_first_item")
	#call_deferred("_on_tree_item_selected")


# called to default the selection to top of spreadsheet when sheet is reloaded
func _select_first_item():
	if tree_root == null:
		return
	var first_tree_item = tree_root.get_child(0)
	if first_tree_item is TreeItem:
		first_tree_item.select(0)
		database_tree.grab_focus()
