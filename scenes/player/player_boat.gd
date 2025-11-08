extends CharacterBody2D

@export var acceleration := 30.0
@export var deceleration := 10.0
@export var max_speed := 60.0
@export var reverse_speed := 60.0
@export var turn_speed := 1.0

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

var current_speed: float = 0.0
var turn_inertia: float = 0.0  # tiny smoothing for nicer feel

# --- tiny feel constants (not radical) ---
var idle_drift_speed: float = 5.0        # "move very slowly when not moving"
var idle_turn_factor: float = 0.35       # % of turn_speed you get even at 0 speed
var turn_inertia_gain: float = 12.0      # responsiveness of turn input
var turn_inertia_decay: float = 10.0     # how fast it decays when you stop pressing

func enable_controls() -> void:
	controls_enabled = true

func disable_controls() -> void:
	controls_enabled = false

func _physics_process(delta: float) -> void:
	# Camera sway (waves / motion feel)
	var cam: Camera2D = $Camera2D
	var sway: float = sin(float(Time.get_ticks_msec()) * 0.0015) * (abs(current_speed) / max_speed) * 0.5
	cam.offset = Vector2(sway, -sway * 0.4)
	
	# If controls are disabled, just slow to a stop and don't accept input
	if not controls_enabled:
		current_speed = lerp(current_speed, 0.0, 0.1)
		velocity = (FORWARD_BASE * current_speed).rotated(rotation)
		move_and_slide()
		return

	# Player input
	var turn_input: float = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		turn_input -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		turn_input += 1.0

	# boat can still rotate when stopped, but turns better with speed
	var speed_ratio: float = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
	var effective_turn: float = turn_speed * (idle_turn_factor + (1.0 - idle_turn_factor) * speed_ratio)

	# a hint of turn inertia for juice (very light)
	turn_inertia = lerp(turn_inertia, turn_input, clamp(turn_inertia_gain * delta, 0.0, 1.0))
	# decay when no input
	if is_zero_approx(turn_input):
		turn_inertia = lerp(turn_inertia, 0.0, clamp(turn_inertia_decay * delta, 0.0, 1.0))

	rotation += effective_turn * turn_inertia * delta

	# throttle/brake
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		current_speed += acceleration * delta
	elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		current_speed -= deceleration * delta
	else:
		# glide down toward a tiny idle drift forward for “always slightly moving”
		var target_idle := idle_drift_speed
		current_speed = move_toward(current_speed, target_idle, 20.0 * delta)

	# fire controls
	if Input.is_action_just_pressed("fire_left"):
		fire_left_guns()
	if Input.is_action_just_pressed("fire_right"):
		fire_right_guns()

	# clamps and motion
	current_speed = clamp(current_speed, -reverse_speed, max_speed)
	velocity = (FORWARD_BASE * current_speed).rotated(rotation)
	move_and_slide()

	update_guns_visibility()
	update_knots_display()

func update_knots_display() -> void:
	knots = int(round(abs(current_speed) / 10.0))

func update_guns_visibility() -> void:
	var guns_node: Node = $Guns
	var total: int = guns_node.get_child_count()

	for i in range(total):
		var child := guns_node.get_child(i) as CanvasItem
		if child:
			child.visible = (i < guns)

func fire_left_guns() -> void:
	if not can_fire_left:
		return
	can_fire_left = false

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 1:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	# start cooldown timer
	var t: SceneTreeTimer = get_tree().create_timer(left_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_left = true)

func fire_right_guns() -> void:
	if not can_fire_right:
		return
	can_fire_right = false

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 0:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	# start cooldown timer
	var t: SceneTreeTimer = get_tree().create_timer(right_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_right = true)
