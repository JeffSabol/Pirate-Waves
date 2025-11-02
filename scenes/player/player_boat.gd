extends CharacterBody2D

@export var acceleration := 60.0
@export var deceleration := 40.0
@export var max_speed := 220.0
@export var reverse_speed := 60.0
@export var turn_speed := 2.0

# Let us toggle control in the editor or from another script
@export var controls_enabled := true

const FORWARD_BASE := Vector2.UP

var current_speed := 0.0

func enable_controls():
	controls_enabled = true

func disable_controls():
	controls_enabled = false

func _physics_process(delta):
	# If controls are disabled, just slow to a stop and don't accept input
	if not controls_enabled:
		current_speed = lerp(current_speed, 0.0, 0.1)
		velocity = (FORWARD_BASE * current_speed).rotated(rotation)
		move_and_slide()
		return

	# Player input
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		rotation -= turn_speed * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		rotation += turn_speed * delta

	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		current_speed += acceleration * delta
	elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		current_speed -= deceleration * delta
	else:
		current_speed = lerp(current_speed, 0.0, 0.02)

	current_speed = clamp(current_speed, -reverse_speed, max_speed)
	velocity = (FORWARD_BASE * current_speed).rotated(rotation)
	move_and_slide()
