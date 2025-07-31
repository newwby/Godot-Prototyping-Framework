@tool
extends Control

#####################################################################

const DB_FIELD_MIN_WIDTH := 35

var tree_columns := []
var tree_root: TreeItem

# copies the schema from Data.schema_register for data validation
var active_schema: Dictionary = {}
# cached on schema change
var active_schema_id: String = ""
var active_schema_version: String = ""

# main database
@onready var database_tree = %DatabaseTree

# top bar/filter controls
@onready var filter_schema_id = %FilterSchemaID
@onready var filter_schema_version = %FilterSchemaVersion

@onready var filter_author = %FilterAuthor
@onready var filter_package = %FilterPackage
@onready var filter_type = %FilterType
@onready var filter_tag = %FilterTag

# bottom bar controls
@onready var id_label = %IDLabel
@onready var path_label = %PathLabel

#####################################################################

# virt


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_setup_id_filter()
	_initial_tree_setup()
	# display from initial schema version/id
	_on_filter_schema_id_item_selected(filter_schema_id.selected)


#####################################################################

# public methods


#//TODO cache in this script
# as populated from Data.schema_register this will correspond to a schema_id
func get_selected_schema_id() -> String:
	var schema_id_idx = filter_schema_id.selected
	var schema_id_text = filter_schema_id.get_item_text(schema_id_idx)
	return schema_id_text


#//TODO cache in this script
# as populated from Data.schema_register this will correspond to a schema_version
#	from the matching schema_Id
func get_selected_schema_version() -> String:
	var schema_ver_idx = filter_schema_version.selected
	var schema_ver_text = filter_schema_version.get_item_text(schema_ver_idx)
	return schema_ver_text


##############################################################################

# private methods


func _cache_schema() -> void:
	var schema_id = get_selected_schema_id()
	var schema_ver = get_selected_schema_version()
	var all_schema_vers = Data.schema_register.get(schema_id, [])
	active_schema = all_schema_vers.get(schema_ver, {})
	active_schema_id = schema_id
	active_schema_version = schema_ver
	if active_schema == {}:
		Log.error(self, "invalid schema lookup {0}.{1}".format([schema_id, schema_ver]))


#//TODO move _init_database behaviour into here for schema 
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
	database_tree.item_edited.connect(_on_tree_item_edited)
	database_tree.item_selected.connect(_on_tree_item_selected)
	tree_root = database_tree.create_item()

# data entry paths are indexed by the tree item displaying their value
# {TreeItem: String}
var uid_map := {}

func _load_data_entry(data_entry: Dictionary) -> void:
	var new_row: TreeItem = database_tree.create_item(tree_root)
	# id is immutable (#//TODO for now) value defining the data entry in display
	var data_id = "{0}.{1}.{2}".format([
		data_entry.get("id_author", "?"),
		data_entry.get("id_package", "?"),
		data_entry.get("id_name", "?")
	])
	
	# inject the concatenated id
	data_entry["id"] = data_id
	# flatten the schema data entry
	var entry_schema_data = data_entry.get("data", {})
	for schema_key in entry_schema_data:
		data_entry[schema_key] = entry_schema_data[schema_key]
	
	for idx in range(tree_columns.size()):
		var key = tree_columns[idx]
		var value = data_entry.get(key, null)
		new_row.set_text(idx, str(value))
		new_row.set_autowrap_mode(idx, TextServer.AUTOWRAP_WORD_SMART)
		new_row.set_tooltip_text(idx, "")
		# id is not editable
		new_row.set_editable(idx, (key != "id"))
	
	# index the data value
	var path = data_entry.get("path", null)
	if path == null:
		Log.warning(self, "cannot load path from data_entry: {0}".format([data_entry]))
	uid_map[new_row] = path


# pass an array of data values (e.g. the .values() property of a Data.*register)
#	and the plugin will load as the displayed data (assuming it matches schema)
func _load_data_list(data_list: Array) -> void:
	for item in data_list:
		if typeof(item) == TYPE_DICTIONARY:
			# now-optional verification step removed as GlobalData fetch is
			#	more granular and grabs specific cache/doesn't pull all information
			#if _verify_data_entry(item):
			_load_data_entry(item)


func _load_filters() -> void:
	filter_author.clear()
	filter_author.add_item("All Authors")
	var schema_author_keys = Data.get_available_authors(active_schema_id, active_schema_version)
	#filter_author.visible = (!schema_author_keys.is_empty())
	for key in schema_author_keys:
		filter_author.add_item(key)
	
	filter_package.clear()
	filter_package.add_item("All Packages")
	var schema_package_keys = Data.get_available_packages(active_schema_id, active_schema_version)
	#filter_package.visible = (!schema_package_keys.is_empty())
	for key in schema_package_keys:
		filter_package.add_item(key)
	
	filter_type.clear()
	filter_type.add_item("All Types")
	var schema_type_keys = Data.get_available_types(active_schema_id, active_schema_version)
	#filter_type.visible = (!schema_type_keys.is_empty())
	for key in schema_type_keys:
		filter_type.add_item(key)
	
	filter_tag.clear()
	filter_tag.add_item("All Tags")
	var schema_tag_keys = Data.get_available_tags(active_schema_id, active_schema_version)
	#filter_tag.visible = (!schema_tag_keys.is_empty())
	for key in schema_tag_keys:
		filter_tag.add_item(key)


# when schema id is changed in the dropdown control
#	update the schema versions
#	default to the highest version
func _on_filter_schema_id_item_selected(index):
	#print(filter_schema_id.selected, " - {0}".format([filter_schema_id.get_item_text(filter_schema_id.selected)]))
	#var current_schema = active_schema_id
	# need to call to get_id as hasn't been set when this is called before cache_schema
	# cache schema called in _reload_database currently, needs to be moved earlier
	var new_schema = get_selected_schema_id()
	#print(current_schema, " -> ", new_schema)
	var schema_versions = Data.schema_register.get(new_schema, [])
	#print("schema versions = ", schema_versions, " from ", new_schema)
	# setup the version dropdown
	filter_schema_version.clear()
	for i in schema_versions:
		filter_schema_version.add_item(i)
	# default to most recent version
	var idx = filter_schema_version.item_count-1
	filter_schema_version.select(idx)
	_reload_database()


# whenever the schema version, or any filter option, is changed
func _on_filter_item_selected(_index):
	_reload_database()


func _on_tree_item_edited() -> void:
	pass
	#var item: TreeItem = database_tree.get_edited()
	#var edited_col = database_tree.get_edited_column()
	#var new_text = item.get_text(edited_col)


func _on_tree_item_selected() -> void:
	var item: TreeItem = database_tree.get_selected()
	if item != null:
		var selected_text = item.get_text(0)
		var set_selection_text := "{0} ({1} {2})".format([selected_text, active_schema_id, active_schema_version])
		id_label.text = set_selection_text
		
		var record_path = uid_map.get(item, null)
		if typeof(record_path) == TYPE_STRING:
			path_label.text = record_path

#// Behaviour for when plugin panel is shown
#//TODO legacy? Remove?
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		pass


# changes the cached schema data & repopulates the database
func _reload_database() -> void:
	# cache current schema
	_cache_schema()
	# write the database
	_reload_tree_by_schema()
	
	var query := {}
	# filters are populated from schema keys so text will be valid for query
	var author: String = filter_author.get_item_text(filter_author.selected)
	var package: String = filter_package.get_item_text(filter_package.selected)
	var type: String = filter_type.get_item_text(filter_type.selected)
	var tag: String = filter_tag.get_item_text(filter_tag.selected)
	
	query["schema_id"] = active_schema_id
	query["schema_version"] = active_schema_version
	
	if author != "All Authors":
		query["id_author"] = author
	if package != "All Packages":
		query["id_package"] = package
	if package != "All Types":
		query["type"] = type
	if package != "All Tags":
		query["tags"] = tag
	
	var data_list = Data.fetch(query)
	
	#//TODO filters shouldn't reload unless schema has changed
	#//TODO cache the schema id/ver and check if changed before reloading filters
	# 	and changing the selected item - item should persist between
	#//TODO confirm that resetting to 'all' reloads all
	#//TODO confirm can search by multiple filters once they persist
	_load_filters()
	
	_load_data_list(data_list)
	call_deferred("_select_first_item")


# Called whenever the schema id/version changes, and on initial load
# Completely resets the displayed database content according to current schema
# Maps the column index
func _reload_tree_by_schema() -> void:
	# refresh the tree root
	_clear_tree()
	
	if active_schema.is_empty():
		Log.error(self, "cannot write database with inactive schema")
		return
	
	tree_columns = ["id", "type", "tags"]
	tree_columns.append_array(active_schema.keys())
	
	database_tree.columns = tree_columns.size()
	
	for i in range(tree_columns.size()):
		database_tree.set_column_title(i, tree_columns[i])
		database_tree.set_column_custom_minimum_width(i, DB_FIELD_MIN_WIDTH)
		database_tree.set_column_expand(i, true)
		database_tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)


# called to default the selection to top of spreadsheet when sheet is reloaded
func _select_first_item():
	if tree_root == null:
		return
	var first_tree_item = tree_root.get_child(0)
	if first_tree_item is TreeItem:
		first_tree_item.select(0)
		database_tree.grab_focus()


# get schema ids from Data.schema_register on setup
func _setup_id_filter() -> void:
	filter_schema_id.clear()
	for schema_id in Data.schema_register.keys():
		filter_schema_id.add_item(schema_id)


# data must match the active schema to pass validation & enter the db
func _verify_data_entry(data_entry: Dictionary) -> bool:
	#//TOOD cache this
	# check matching identifier keys
	if data_entry.get("schema_id", null) != active_schema_id\
	or data_entry.get("schema_version", null) != active_schema_version:
		return false
	# check data values
	var schema_data = data_entry.get("data", {})
	for key in active_schema.keys():
		if schema_data.has(key) == false:
			return false
	# else
	return true
