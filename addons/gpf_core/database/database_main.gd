extends MarginContainer

@export var headings = ["heading1", "heading2", "heading3"]
@export var test_data = [
	{
		"heading1": 42,
		"heading2": "hellow world",
		"heading3": Vector2.ZERO
	},
	{
		"heading1": 1337,
		"heading2": "goodbye world",
		"heading3": Vector2.LEFT
	},
	{
		"heading1": 127,
		"heading2": "50+50",
		"heading3": Rect2(Vector2.ZERO, Vector2.ONE)
	},
	{
		"heading1": 117,
		"heading2": "str entry",
		"heading3": 42.0
	},
]

# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

#extends Control

var grid_size = Vector2(10, 10)
var cells = []

func _ready():
	create_grid(grid_size.x, grid_size.y)

func create_grid(columns: int, rows: int):
	var grid = GridContainer.new()
	grid.columns = columns
	add_child(grid)
	
	for row in range(rows):
		var row_cells = []
		for col in range(columns):
			var line_edit = LineEdit.new()
			line_edit.custom_minimum_size = Vector2(100, 30)
			grid.add_child(line_edit)
			row_cells.append(line_edit)
		cells.append(row_cells)

func get_value(row: int, col: int) -> String:
	return cells[row][col].text

func set_value(row: int, col: int, value: String):
	cells[row][col].text = value
