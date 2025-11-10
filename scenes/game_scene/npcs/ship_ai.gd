# ShipAI.gd
extends Node2D
class_name ShipAI

signal despawned

# ---- Internals (typed) ----
var _curve: Curve2D
var _loop: bool = true
var _speed: float = 40.0      # pixels per second along the curve
var _dist: float = 0.0        # distance traveled along the baked curve (pixels)
var _length: float = 0.0      # total baked length (pixels)

# ---- Tuning ----
@export var max_distance_from_player: float = 5000.0

# Facing controls
@export var face_direction: bool = true
@export var turn_speed: float = 6.0              # 0 = snap; higher = smoother snap
@export var rotation_offset_deg: float = 90.0    # set so your sprite "forward" matches +X
@export var look_ahead_px: float = 16.0          # pixels ahead to sample for heading

# Curve fidelity (helps heading match tight turns)
@export var override_bake_interval: float = 0.0  # 0 = keep default; else set in pixels (e.g., 2.0)

# Cannons
@export var left_fire_cooldown := 3
@export var right_fire_cooldown := 3
var can_fire_left := true
var can_fire_right := true
@export var guns := 2

# ---- Aggro / Chase (added) ----
@export var chase_speed: float = 70.0
@export var aggro_preferred_range: float = 380.0   # try to hold a broadside-ish distance
@export var aggro_range_tolerance: float = 80.0    # band around preferred range
@export var aggro_duration: float = 10

var _aggro_time: float = 0.0
var _aggro_target: Node2D

func is_aggro() -> bool:
	return _aggro_time > 0.0 and is_instance_valid(_aggro_target)

func set_aggro(target: Node2D, duration: float) -> void:
	# Always refresh the full duration so it doesn't suddenly stop
	_aggro_target = target
	_aggro_time = duration

func on_hit(attacker: Node) -> void:
	var p := attacker as Node2D
	if p:
		set_aggro(p, aggro_duration)

# ---- Public API ----
func set_path(curve: Curve2D, loop: bool, speed: float, start_t: float) -> void:
	_curve = curve
	_loop = loop
	_speed = speed 
	_dist = 0.0
	_length = 0.0

	if _curve:
		# Optional: increase baked fidelity for better forward vectors on sharp turns
		if override_bake_interval > 0.0:
			_curve.bake_interval = override_bake_interval

		_length = max(float(_curve.get_baked_length()), 0.001)
		# start_t is 0..1; convert to distance
		_dist = clamp(start_t, 0.0, 1.0) * _length
		global_position = _curve.sample_baked(_dist)

func _physics_process(delta: float) -> void:
	# ---- Simple far-away despawn ----
	var player: Node2D = get_tree().get_first_node_in_group("PlayerBoat") as Node2D
	if player and global_position.distance_to(player.global_position) > max_distance_from_player:
		_emit_and_free()
		return

	# ---- AGGRO / CHASE MODE ----
	if is_aggro():
		_aggro_time -= delta
		if not is_instance_valid(_aggro_target):
			_aggro_time = 0.0

		if is_aggro():
			var to_target: Vector2 = _aggro_target.global_position - global_position
			var dist := to_target.length()

			# Maintain a loose ring around the player (approach/hold/back off)
			var lower := float(max(0.0, aggro_preferred_range - aggro_range_tolerance))
			var upper := aggro_preferred_range + aggro_range_tolerance

			# --- compute movement vector ---
			var move := Vector2.ZERO
			if dist > upper:
				# Move in
				move = (to_target / max(1.0, dist)) * chase_speed
			elif dist < lower:
				# Back off a bit
				move = -(to_target / max(1.0, dist)) * chase_speed * 0.6
			else:
				# In band: slight orbit to avoid ramming
				var tangent := Vector2(-to_target.y, to_target.x).normalized()
				move = tangent * chase_speed * 0.35

			# Apply movement
			global_position += move * delta

			# Face the movement direction (like Path2D)
			if face_direction and move.length() > 0.001:
				var desired: float = move.angle() + deg_to_rad(rotation_offset_deg)
				var step: float = clamp(turn_speed * delta, 0.0, 1.0)
				rotation = lerp_angle(rotation, desired, step)

		# If aggro ended this frame, reattach to the path near our current position
		if _aggro_time <= 0.0 and _curve and _length > 0.001:
			# Snap distance to closest offset on the curve so cruise resumes smoothly
			_dist = clamp(_curve.get_closest_offset(global_position), 0.0, _length)

		_fire_if_allowed()
		return

	# ---- CRUISE MODE (your original path-following behavior) ----
	if _curve == null or _length <= 0.001:
		return

	# ---- Advance along the curve by pixels/second ----
	_dist += _speed * delta
	if _loop:
		_dist = fposmod(_dist, _length)
	else:
		if _dist >= _length:
			_emit_and_free()
			return

	# ---- Position ----
	global_position = _curve.sample_baked(_dist)

	# ---- Orientation (face true travel direction) ----
	if face_direction:
		var ahead: float = _dist + look_ahead_px
		if _loop:
			ahead = fposmod(ahead, _length)
		else:
			ahead = clamp(ahead, 0.0, _length)

		var ahead_pos: Vector2 = _curve.sample_baked(ahead)
		var dir: Vector2 = ahead_pos - global_position
		if dir.length() > 0.001:
			var desired: float = dir.angle() + deg_to_rad(rotation_offset_deg)
			var step: float = clamp(turn_speed * delta, 0.0, 1.0)
			rotation = lerp_angle(rotation, desired, step)

	_fire_if_allowed()

func _fire_if_allowed() -> void:
	if (_aggro_time > 0):
		# If we can *see* the player, keep/refresh aggro so it doesn't drop mid-fight
		if $LeftSight.is_colliding() && $LeftSight.get_collider().name == "PlayerBoat":
			set_aggro($LeftSight.get_collider(), aggro_duration) # refresh timer
			if is_aggro():
				fire_left_guns()

		if $RightSight.is_colliding() && $RightSight.get_collider().name == "PlayerBoat":
			set_aggro($RightSight.get_collider(), aggro_duration) # refresh timer
			if is_aggro():
				fire_right_guns()

func _emit_and_free() -> void:
	despawned.emit()
	queue_free()

func set_speed(speed: float) -> void:
	_speed = speed

func set_face_direction(enabled: bool) -> void:
	face_direction = enabled

# TODO i'm sure this can be pulled up into a more general class with playerboat
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
		
func fire_right_guns():
	if not can_fire_right:
		return
	can_fire_right = false

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 0:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	# start cooldown timer (mirrors left)
	var t: SceneTreeTimer = get_tree().create_timer(right_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_right = true)
