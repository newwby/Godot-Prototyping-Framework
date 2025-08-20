@tool
extends Control

#####################################################################

#//TODO
# data files can have additional keys in schema["data"]
#	- how to display and edit?  set_edit_multiline() and display as dict?

# write custom file dialog to prevent going up out of user://data & to hide user://data/_schema

# fit to row width
# horizontal scrolling
# resizable row headers

# _on_tree_item_selected review (selection text specifically)

# _reload_database TODO
#//TODO confirm that resetting to 'all' reloads all
#//TODO confirm can search by multiple filters once they persist
#//TODO reintroduce and fix filtering by tag

#//TODO BUGFIXES
# specifying author & package will show all data if result == 0
# Index out of bounds: attempted to access column 10 in a Tree with only 6 columns.

# newly created row shouldn't appear (hide or delay?) in DB until after ID is confirmed
# _on_create_button_pressed tidy up (file dialog behaviour)
# file dialog should not close if file name is invalid
# _on_create_file_selected needs to validate filename/path before opening id_edit panel

# filter bug on creating file - not populated with new id/type etc
#//TODO new id data doesn't show up in the filter immediately, even when deferred
#	- potential issue is that the file indexing by GlobalData is also deferred

#//TODO deindex data would be less invasive on _on_delete_button (rather than full GData reload)
#//TODO _on_edit_id_button_pressed keyboard shortcut or row shortcut
#//TODO _on_id_confirm_panel_id_changed - need to handle validation/if null

#####################################################################

const DB_FIELD_MIN_WIDTH := 35

var tree_columns := []
var tree_root: TreeItem

# data entry paths are indexed by the tree item displaying their value
# {TreeItem: String}
var uid_map := {}

# copies the schema from Data.schema_register for data validation
var active_schema: Dictionary = {}
# cached on schema change
var active_schema_id: String = ""
var active_schema_version: String = ""

# reusing id_confirm_panel for creating new records & editing row ids so
#	need to differentiate
var is_creating_file := false
var is_editing_id := false

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
@onready var create_record_button = $Scroll/VBox/BottomBar/Margin/HBox/CRUD/Create
@onready var delete_record_button = $Scroll/VBox/BottomBar/Margin/HBox/CRUD/Delete
@onready var edit_record_id_button = $Scroll/VBox/BottomBar/Margin/HBox/CRUD/Edit

@onready var id_confirm_panel = %IDConfirmPanel

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


# returns whether the schema changed or not - determines whether to reload filters
func _cache_schema() -> bool:
	var schema_id = get_selected_schema_id()
	var schema_ver = get_selected_schema_version()
	var all_schema_vers = Data.schema_register.get(schema_id, [])
	active_schema = all_schema_vers.get(schema_ver, {})
	
	var has_schema_changed := false
	if active_schema_id != schema_id\
	or active_schema_version != schema_ver:
		has_schema_changed = true
	
	active_schema_id = schema_id
	active_schema_version = schema_ver
	if active_schema == {}:
		Log.error(self, "invalid schema lookup {0}.{1}".format([schema_id, schema_ver]))
	return has_schema_changed


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
	database_tree.item_edited.connect(_on_tree_item_edited)
	database_tree.item_selected.connect(_on_tree_item_selected)
	create_record_button.pressed.connect(_on_create_button_pressed)
	delete_record_button.pressed.connect(_on_delete_button_pressed)
	edit_record_id_button.pressed.connect(_on_edit_id_button_pressed)
	tree_root = database_tree.create_item()
	call_deferred("_select_first_item")


func _load_data_entry(data_entry: Dictionary) -> void:
	var new_row: TreeItem = database_tree.create_item(tree_root)
	if new_row == null:
		return
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
		
		if key == "tags":
			value = Data.decode_tags(value)
		
		new_row.set_text(idx, str(value))
		new_row.set_autowrap_mode(idx, TextServer.AUTOWRAP_WORD_SMART)
		new_row.set_tooltip_text(idx, "")
		# id is not editable
		new_row.set_editable(idx, (key != "id"))
	
	# index the data value
	var path = data_entry.get("path", null)
	if path == null:
		Log.warning(self, "_load_data_entry: cannot load path from data_entry: {0}".format([data_entry]))
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
		filter_tag.add_item(str(key))


# Called whenever the schema id/version changes, and on initial load
# Completely resets the displayed database content according to current schema
# Maps the column index
func _load_tree_structure() -> void:
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


func _on_create_button_pressed() -> void:
	is_creating_file = true
	is_editing_id = false
	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_USERDATA
	#file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_dir = Data.get_user_data_path()
	file_dialog.title = "Select Save Location"
	file_dialog.file_selected.connect(_on_create_file_selected)
	file_dialog.add_filter("*.json ; JSON Files")
	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	add_child(file_dialog)
	file_dialog.popup_centered()


func _on_create_file_selected(path: String) -> void:
	# fix path if no extension
	if not path.ends_with(".json"):
		path += ".json"
	
	if path.get_file().get_basename() == "":
		Log.warning(self, "Did not specify any file name")
		return
	elif path.get_file().is_valid_filename() == false:
		Log.warning(self, "Did not specify valid file name")
		return
	
	var placeholder_data := {
		"schema_id": active_schema_id,
		"schema_version": active_schema_version,
		"data": active_schema,
		"path": path
	}
	
	id_confirm_panel.open_panel("", "", "")
	
	_load_data_entry(placeholder_data)
	tree_root.select(tree_root.get_child_count())
	# discard filter selections as we want confirmation of the new file appearing
	self.call_deferred("_load_filters")


func _on_delete_button_pressed() -> void:
	var selected_row: TreeItem = database_tree.get_selected()
	if selected_row != null:
		var default_arg = "[no path]"
		var uid_path = uid_map.get(selected_row, default_arg)
		if uid_path == default_arg:
			Log.error(self, "_on_delete_button_pressed can't find path for selected file")
			return
		else:
			DataUtility.delete_file(uid_path)
			Data.reload_data()
			call_deferred("_reload_database")


func _on_edit_id_button_pressed() -> void:
	is_creating_file = false
	is_editing_id = true
	
	var selected_row: TreeItem = database_tree.get_selected()
	if selected_row == null:
		Log.warning(self, "no selected button; _on_edit_id_button_pressed")
		return
	var id_text = selected_row.get_text(0)
	var id_text_split = id_text.split(".")
	if id_text_split.size() != 3:
		Log.error(self, "invalid id")
	var id_author = id_text_split[0]
	var id_package = id_text_split[1]
	var id_name = id_text_split[2]
	
	if is_instance_valid(id_confirm_panel):
		id_confirm_panel.open_panel(id_author, id_package, id_name)
	else:
		Log.error(self, "null id_confirm_panel on edit id button pressed")


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


func _on_id_confirm_panel_id_changed(author, package, name):
	for validate_arg in [author, package, name]:
		if typeof(validate_arg) != TYPE_STRING:
			Log.error(self, "invalid argument type in _on_id_confirm_panel_id_changed")
			return
		if validate_arg == "":
			Log.warning(self, "id argument cannot be blank")
			_reload_database()
			return
	
	var item: TreeItem = null
	if is_editing_id:
		item = database_tree.get_selected()
	if is_creating_file:
		item = tree_root.get_child(tree_root.get_child_count()-1)
	
	# adjust id
	if item != null:
		item.set_text(0, "{0}.{1}.{2}".\
				format([str(author), str(package), str(name)
				]))
		_resave_row(item)


func _on_tree_item_edited() -> void:
	var item: TreeItem = database_tree.get_edited()
	var is_valid = _validate_row(item)
	if is_valid:
		_resave_row(item)


func _on_tree_item_selected() -> void:
	if is_instance_valid(id_label) == false\
	or is_instance_valid(path_label) == false:
		return
	var item: TreeItem = database_tree.get_selected()
	edit_record_id_button.disabled = (item == null)
	if item != null:
		var selected_text = item.get_text(0)
		var set_selection_text := "{0} ({1} {2})".format([selected_text, active_schema_id, active_schema_version])
		id_label.text = set_selection_text
		var record_path = uid_map.get(item, null)
		if record_path == null:
			path_label.text = ""
		if typeof(record_path) == TYPE_STRING:
			path_label.text = record_path

#// Behaviour for when plugin panel is shown
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		pass


# changes the cached schema data & repopulates the database
func _reload_database() -> void:
	# cache current schema
	var has_schema_changed: bool = _cache_schema()
	# write the database, reload according to schema
	_load_tree_structure()
	
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
	
	if has_schema_changed:
		_load_filters()
	_load_data_list(data_list)
	_validate_all_rows()
	call_deferred("_select_first_item")
	call_deferred("_on_tree_item_selected")


func _resave_row(row: TreeItem) -> void:
	if row == null:
		Log.error(self, "invalid arg for _resave_row")
		return
	# else
	var key
	var value
	var save_data = {}
	var file_path = uid_map.get(row, null)
	if file_path == null:
		return
	
	for expected_key in Data.EXPECTED_DATA_STRUCTURE.keys():
		save_data[expected_key] = null
	save_data["schema_id"] = active_schema_id
	save_data["schema_version"] = active_schema_version
	save_data["data"] = {}
	for i in range(tree_columns.size()):
		key = tree_columns[i]
		value = row.get_text(i)
		
		var is_id = (key == "id")
		var is_mandatory = (key in Data.EXPECTED_DATA_STRUCTURE.keys())
		var in_schema = (key in active_schema.keys())
		
		if is_id:
			var id_split = value.split(".")
			var id_author = id_split[0]
			var id_package = id_split[1]
			var id_name = id_split[2]
			save_data["id_author"] = id_author
			save_data["id_package"] = id_package
			save_data["id_name"] = id_name
		if is_mandatory:
			if key == "tags":
				save_data[key] = Data.encode_tags(value)
			else:
				save_data[key] = value
		if in_schema:
			var type = typeof(active_schema[key])
			var saved_value = value
			match type:
				TYPE_FLOAT:
					if value.is_valid_float():
						saved_value = float(value)
				TYPE_INT:
					if value.is_valid_int():
						saved_value = float(value)
				#TYPE_ARRAY:
					#saved_value = [value]
			save_data["data"][key] = saved_value
	
	if file_path != null:
		DataUtility.save_json(save_data, file_path)
		Data.reload_data()
		call_deferred("_reload_database")


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


func _validate_all_rows() -> void:
	if tree_root == null:
			return
	for row in tree_root.get_children():
		_validate_row(row)


# checks all data in the tree for if invalid - shows visual display if invalid
# pass a TreeItem to validate the data in that row
func _validate_row(row: TreeItem) -> bool:
	if row == null:
		Log.error(self, "null arg passed to _validate_row")
		return false
	# don't show errors on unmapped rows, e.g. the add new record row
	if !(row in uid_map.keys()):
		return true
	
	var key
	var value
	var invalid_columns := PackedInt32Array([])
	
	for i in range(tree_columns.size()):
		row.clear_custom_bg_color(i)
		row.set_tooltip_text(i, "")
		key = tree_columns[i]
		value = row.get_text(i)
		if key in tree_columns:
			if _validate_value(key, value) == false:
				invalid_columns.append(i)
	
	if (invalid_columns.is_empty() == false):
		for i in invalid_columns:
			row.set_custom_bg_color(i, Color.RED, false)
			row.set_tooltip_text(i, "Invalid value")
		return false
	else:
		return true


# confirms whether a value type & expected structure matches schema
func _validate_value(key, value) -> bool:
	#print("validate - ", key, " ", value)
	var value_type = typeof(value)
	
	# specific handling for ID & tag
	# id has to match a format
	match key:
		"id":
			var value_split = str(value).split(".")
			if value_split.size() != 3:
				return false
			for substr in value_split:
				if str(substr) == "":
					return false
			# else
			return true
		
		# tags are converted to string when displayed in filter
		"tags":
			if typeof(value) != TYPE_STRING:
				return false
			else:
				return true
		
		# otherwise check against expected data structure or schema
		_:
			# check if mandatory key other than id/tags
			if key in Data.EXPECTED_DATA_STRUCTURE.keys():
				# expected data structure values are typeof results
				return typeof(key) == Data.EXPECTED_DATA_STRUCTURE[key]
			
			# check if in schema/data
			elif key in active_schema.keys():
				var schema_type = typeof(active_schema[key])
				var saved_value = value
				match schema_type:
					TYPE_FLOAT:
						if value_type == TYPE_STRING:
							return value.is_valid_float()
						else:
							return (value_type == TYPE_FLOAT)
					TYPE_INT:
						if value_type == TYPE_STRING:
							return value.is_valid_int()
						else:
							return (value_type == TYPE_INT)
					_:
						return typeof(value) == schema_type
			else:
				Log.warning(self, "_validate_value -> key {0} not found".format([key]))
				return false


# data must match the active schema to pass validation & enter the db
func _verify_data_entry(data_entry: Dictionary) -> bool:
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
