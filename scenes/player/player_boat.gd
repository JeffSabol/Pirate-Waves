extends CharacterBody2D

@export var acceleration := 60.0
@export var deceleration := 40.0
@export var max_speed := 220.0
@export var reverse_speed := 60.0
@export var turn_speed := 2.0

const FORWARD_BASE := Vector2.UP  # <- UP because the sprite faces north at 0°

var current_speed := 0.0

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		rotation -= turn_speed * delta
	if Input.is_action_pressed("ui_right"):
		rotation += turn_speed * delta

	if Input.is_action_pressed("ui_up"):
		current_speed += acceleration * delta
	elif Input.is_action_pressed("ui_down"):
		current_speed -= deceleration * delta
	else:
		current_speed = lerp(current_speed, 0.0, 0.02)

	current_speed = clamp(current_speed, -reverse_speed, max_speed)

	velocity = (FORWARD_BASE * current_speed).rotated(rotation)
	move_and_slide()
