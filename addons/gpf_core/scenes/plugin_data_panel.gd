@tool
extends Control

#####################################################################

const DB_FIELD_MIN_WIDTH := 50

const EXCLUDED_KEYS := ["schema_id", "schema_version"]

var tree_root: TreeItem

# copies the schema from Data.schema_register for data validation
var active_schema: Dictionary = {}

# main database
@onready var database_tree = %DatabaseTree

# filter controls
@onready var filter_schema_id = %FilterSchemaID
@onready var filter_schema_version = %FilterSchemaVersion

#####################################################################

# virt


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_init_database()
	_setup_id_filter()
	# display from initial schema version/id
	_on_filter_schema_id_item_selected(filter_schema_id.selected)


#####################################################################

# public methods


# as populated from Data.schema_register this will correspond to a schema_id
func get_selected_schema_id() -> String:
	var schema_id_idx = filter_schema_id.selected
	var schema_id_text = filter_schema_id.get_item_text(schema_id_idx)
	return schema_id_text


# as populated from Data.schema_register this will correspond to a schema_version
#	from the matching schema_Id
func get_selected_schema_version() -> String:
	var schema_ver_idx = filter_schema_version.selected
	var schema_ver_text = filter_schema_version.get_item_text(schema_ver_idx)
	return schema_ver_text


##############################################################################

# private methods


#//TODO move _init_database behaviour into here for schema 
func _clear_database() -> void:
	var child := tree_root.get_first_child()
	while child:
		var next = child.get_next()
		child.call_deferred("free")
		child = next


func _init_database() -> void:
	database_tree.clear()
	tree_root = database_tree.create_item()
	database_tree.hide_root = true
	database_tree.item_edited.connect(_on_tree_item_edited)
	
	var columns := Data.EXPECTED_DATA_STRUCTURE.keys()
	for key in EXCLUDED_KEYS:
		columns.erase(key)
	database_tree.columns = columns.size()
	
	for i in range(columns.size()):
		database_tree.set_column_title(i, columns[i])
		database_tree.set_column_expand(i, false)
		database_tree.set_column_custom_minimum_width(i, DB_FIELD_MIN_WIDTH)
		database_tree.set_column_expand(i, true)


# changes the cached schema data & repopulates the database
func _load_database() -> void:
	# cache current schema
	var schema_id = get_selected_schema_id()
	var schema_ver = get_selected_schema_version()
	var all_schema_vers = Data.schema_register.get(schema_id, [])
	active_schema = all_schema_vers.get(schema_ver, {})
	if active_schema == {}:
		Log.error(self, "invalid schema lookup {0}.{1}".format([schema_id, schema_ver]))
	
	# write the database
	_clear_database()
	_populate_database()


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
	filter_schema_version.select(idx)
	_load_database()


# when schema version is changed update the data
func _on_filter_schema_version_item_selected(index):
	#print(filter_schema_version.selected, " - {0}".format([filter_schema_version.get_item_text(filter_schema_version.selected)]))
	# temp handling - clearing the entire tree is a bit messy
	_load_database()

# Currently just debug prints the edited item
#//TODO setup UID logging from path
func _on_tree_item_edited() -> void:
	var edited_item: TreeItem = database_tree.get_edited()
	var edited_col = database_tree.get_edited_column()
	var new_text = edited_item.get_text(edited_col)
	print("{0} - {1} - {2}".format([edited_item, edited_col, new_text]))
	for i in database_tree.columns:
		print(edited_item.get_text(i))


#// Behaviour for when plugin panel is shown
#//TODO legacy? Remove?
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		pass


func _populate_database() -> void:
	#tree_root.c
	for item in Data.data_collection:
		if typeof(item) == TYPE_DICTIONARY:
			_populate_record(item)


# record is validated if it's from global Data registers
# adds record to the database view
func _populate_record(arg_data: Dictionary) -> void:
	if _temp_validate_item(arg_data) == false:
		return
	var columns := Data.EXPECTED_DATA_STRUCTURE.keys()
	for key in EXCLUDED_KEYS:
		columns.erase(key)
	var row = database_tree.create_item(tree_root)
	for i in range(columns.size()):
		var key = columns[i]
		var value = arg_data.get(key, "")
		row.set_text(i, str(value))
		row.set_editable(i, true)
		row.set_autowrap_mode(i, TextServer.AUTOWRAP_WORD_SMART)
		row.set_tooltip_text(i, "")
		#row.set_tooltip_text(i, columns[i])


# get schema ids from Data.schema_register on setup
func _setup_id_filter() -> void:
	filter_schema_id.clear()
	for schema_id in Data.schema_register.keys():
		filter_schema_id.add_item(schema_id)


#//TODO remove
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
