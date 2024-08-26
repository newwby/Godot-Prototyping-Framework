extends Node2D

@export var move_speed: float = 500.0

var velocity := Vector2.ZERO

func _process(_delta: float) -> void:
	handle_input()
	move_and_slide()

func handle_input() -> void:
	velocity = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1

	velocity = velocity.normalized() * move_speed

func move_and_slide() -> void:
	position += velocity * get_process_delta_time()

