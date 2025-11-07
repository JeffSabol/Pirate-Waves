extends CharacterBody2D

@export var acceleration := 30.0
@export var deceleration := 10.0
@export var max_speed := 60.0
@export var reverse_speed := 60.0
@export var turn_speed := 2.0

@export var hp := 100
@export var gold := 0
@export var guns := 2
# KNOTS
# 1 knot = 10 speed
# Level 1 (small sloop / default): 6 knots
# Level 2 (sloop): 9 knots
# Level 3 (brig): 12 knots
# Level 4 (frigate): 14 knots
@export var knots := 0
@export var morale := 0
@export var left_fire_cooldown := 3
@export var right_fire_cooldown := 3
# Let us toggle control in the editor or from another script
@export var controls_enabled := true
var can_fire_left := true
var can_fire_right := true

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
		
	if Input.is_action_just_pressed("fire_left"):
		print("fire left!")
		fire_left_guns()
	if Input.is_action_just_pressed("fire_right"):
		print("fire right!")
		fire_right_guns()

	current_speed = clamp(current_speed, -reverse_speed, max_speed)
	velocity = (FORWARD_BASE * current_speed).rotated(rotation)
	move_and_slide()
	update_guns_visibility()
	update_knots_display()

func update_knots_display():
	knots = int(current_speed) / 10
	
	
func update_guns_visibility():
	var guns_node := $Guns
	var total := guns_node.get_child_count()

	for i in range(total):
		var child := guns_node.get_child(i)
		child.visible = (i < guns)
		
func fire_left_guns():
	if not can_fire_left:
		return

	can_fire_left = false

	var guns_node := $Guns
	for i in range(1, guns + 1):
		if i % 2 == 1:
			var gun = guns_node.get_node("Gun%d" % i)
			gun.fire()

	# start cooldown timer
	var t := get_tree().create_timer(left_fire_cooldown)
	t.timeout.connect(func(): can_fire_left = true)

func fire_right_guns():
	if not can_fire_right:
		return

	can_fire_right = false

	var guns_node := $Guns
	for i in range(1, guns + 1):
		if i % 2 == 0:
			var gun = guns_node.get_node("Gun%d" % i)
			gun.fire()

	# start cooldown timer
	var t := get_tree().create_timer(right_fire_cooldown)
	t.timeout.connect(func(): can_fire_right = true)
