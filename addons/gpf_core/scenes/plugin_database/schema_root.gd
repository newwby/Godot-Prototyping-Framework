extends MarginContainer

##############################################################################

# docs

##############################################################################

# variables

const DB_FIELD_MIN_WIDTH := 100.0

var tree_root: TreeItem

# keys() includes versions
var active_version_list := {}
# corresponds to filter_schema_id text and Data.schema_register.keys()
var active_schema_id := ""

@onready var database_tree = %SchemaDBTree
@onready var schema_editing_panel = %SchemaEditingPanel
@onready var filter_schema_id = %FilterSchemaID
@onready var schema_path_label = %SchemaPath

##############################################################################

# virtual methods


func _ready():
	_initial_tree_setup()
	select_schema_id(Data.schema_register.keys().get(0))


##############################################################################

# public methods


# calls the editing panel
func open_editing_panel(version_id, version_data):
	if is_instance_valid(schema_editing_panel):
		schema_editing_panel.open_panel(version_id, version_data)


# changes the displayed schema (list of versions & their schema values)
func select_schema_id(schema_id_name):
	active_version_list = Data.schema_register.get(schema_id_name)
	if typeof(active_version_list) == TYPE_DICTIONARY:
		active_schema_id = schema_id_name
		if is_instance_valid(schema_path_label):
			var path = Data.schema_unique_path_map.get(active_schema_id, "")
			schema_path_label.text = path
		_reload_database()
	else:
		active_version_list = {}
		Log.error(self, "select_schema_id type error")


##############################################################################

# private methods


# delete all tree items/rows
func _clear_tree() -> void:
	var child := tree_root.get_first_child()
	while child:
		var next = child.get_next()
		child.call_deferred("free")
		child = next
	database_tree.clear()
	tree_root = database_tree.create_item()


func _get_selected_version() -> String:
	var selected_row = database_tree.get_selected()
	if selected_row == null:
		return ""
	var version_key = selected_row.get_text(0)
	return version_key


func _initial_tree_setup() -> void:
	# tree setup
	database_tree.clear()
	database_tree.hide_root = true
	tree_root = database_tree.create_item()
	
	# setup the schema id filter
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
	
	# create new
	var new_row: TreeItem = database_tree.create_item(tree_root)
	if new_row == null:
		return
	
	# set schema version key
	new_row.set_text(0, str(version_key))
	# set schema data values, array decoded as comma separated string
	var schema_data_values = Data.decode_tags(version_data.keys())
	new_row.set_text(1, schema_data_values)
	
	# both aren't editable
	for idx in range(2):
		new_row.set_autowrap_mode(idx, TextServer.AUTOWRAP_WORD_SMART)
		new_row.set_tooltip_text(idx, "")
		new_row.set_editable(idx, false)


func _load_tree_structure() -> void:
	# refresh the tree root
	_clear_tree()
	
	# column headers are always the same for schema
	var tree_columns = ["version", "values"]
	database_tree.columns = tree_columns.size()
	# min value for version, rest of the space for values
	for i in range(tree_columns.size()):
		database_tree.set_column_title(i, tree_columns[i])
		database_tree.set_column_custom_minimum_width(i, DB_FIELD_MIN_WIDTH)
		database_tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	database_tree.set_column_expand(0, false)
	database_tree.set_column_expand(1, true)


func _on_add_version_pressed():
	# pass faked data to the schema editing panel
	var placeholder_version := ""
	var placeholder_data := {
		"String": "",
		"Float": 1.0,
		"Array": []
	}
	open_editing_panel(placeholder_version, placeholder_data)


#//TODO need a popup to enter schema name (also edit functionality)
#//on creating new schema should reload the filter, reload database/GData
func _on_create_new_pressed():
	pass # Replace with function body.


#//TODO should delete the schema file and reload database/GData
func _on_delete_all_pressed():
	pass # Replace with function body.


#//TODO definitely needs confirmation button
func _on_delete_version_pressed():
	var version_key = _get_selected_version()
	if version_key in active_version_list.keys():
		print("erasing ", version_key, " from ", active_version_list)
		active_version_list.erase(version_key)
		print("new list is ", active_version_list)
		_save_schema()
		_reload_database()


func _on_edit_version_pressed():
	var version_key = _get_selected_version()
	var selected_version = active_version_list.get(version_key, {})
	open_editing_panel(version_key, selected_version)


# when the schema ID is changed
func _on_filter_schema_id_item_selected(index):
	if is_instance_valid(filter_schema_id):
		var schema_id = filter_schema_id.get_item_text(index)
		select_schema_id(schema_id)


# on return from editing panel
# need to force overwrite the entry for that version in active_schema_id
#	then push that change back to the file
func _on_schema_editing_panel_update_schema(reference_version_id, updated_version_data):
	if typeof(updated_version_data) == TYPE_DICTIONARY:
		_update_schema_version(str(reference_version_id), updated_version_data)
		_save_schema()
	else:
		Log.error(self, "invalid data type passed to _on_schema_editing_panel_update_schema")


func _reload_database() -> void:
	_load_tree_structure()
	_load_data_list()
	call_deferred("_select_first_item")


# saves the version list/active schema to disk
func _save_schema() -> void:
	if active_schema_id in Data.schema_unique_path_map.keys():
		var schema_file_path = Data.schema_unique_path_map[active_schema_id]
		var data_to_save = active_version_list.duplicate()
		if schema_file_path != null:
			DataUtility.save_json(data_to_save, schema_file_path)
			Data.reload_data()
			call_deferred("_reload_database")


# used in _update_schema_version
# supports fixed values
# if the data type has changed, insert fake value
#//TODO adjust schema editor to allow custom default values instead of hardcoded
func _get_typed_dummy_data(value_type: int):
	match value_type:
		TYPE_STRING:
			return ""
		TYPE_FLOAT:
			return 1.0
		TYPE_ARRAY:
			return []
		TYPE_DICTIONARY:
			return {}
		_:
			Log.error(self, "_get_typed_dummy_data passed invalid value type")
			return null


# updates the active schema in preparation to resave the entire file
func _update_schema_version(ver_id: String, new_schema_data: Dictionary) -> void:
	var original_schema_data = active_version_list.get(ver_id, {})
	
	# new_schema_data is the authortiy
	var data_to_save = new_schema_data.duplicate()
	
	# if key already existed, and type hasn't changed, preserve value
	for key in new_schema_data.keys():
		if key in original_schema_data.keys():
			# check types
			var new_type = typeof(new_schema_data[key])
			var original_type = typeof(original_schema_data[key])
			if new_type != original_type:
				var new_data = _get_typed_dummy_data(new_type)
				if new_data != null:
					data_to_save[key] = new_data
	
	active_version_list[ver_id] = data_to_save


# called to default the selection to top of spreadsheet when sheet is reloaded
func _select_first_item():
	if tree_root == null:
		return
	var first_tree_item = tree_root.get_child(0)
	if first_tree_item is TreeItem:
		first_tree_item.select(0)
		database_tree.grab_focus()
