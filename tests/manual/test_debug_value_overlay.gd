extends Node2D

@onready var player_node = $PlayerSprite


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(0.05).timeout
	GlobalDebug.add_debug_value(player_node, "velocity:x", "velocity_x", "", "", DebugValue.POSITION.TOP_LEFT)
	GlobalDebug.add_debug_value(player_node, "velocity:y", "velocity_y", "", "", DebugValue.POSITION.TOP_LEFT)
	GlobalDebug.add_debug_value(player_node, "velocity", "velocity", "", "", DebugValue.POSITION.TOP_RIGHT)

