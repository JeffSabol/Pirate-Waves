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
@export var rotation_offset_deg: float = 90.0   # set so your sprite "forward" matches +X
@export var look_ahead_px: float = 16.0          # pixels ahead to sample for heading

# Curve fidelity (helps heading match tight turns)
@export var override_bake_interval: float = 0.0  # 0 = keep default; else set in pixels (e.g., 2.0)

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

	# ---- Simple far-away despawn ----
	var player: Node2D = get_tree().get_first_node_in_group("PlayerBoat") as Node2D
	if player and global_position.distance_to(player.global_position) > max_distance_from_player:
		_emit_and_free()

	if ($LeftSight.is_colliding()):
		if $LeftSight.get_collider().name == "PlayerBoat":
			fire_left()

	if ($RightSight.is_colliding()):
		if $RightSight.get_collider().name == "PlayerBoat":
			fire_right()

func _emit_and_free() -> void:
	despawned.emit()
	queue_free()

func set_speed(speed: float) -> void:
	_speed = speed

func set_face_direction(enabled: bool) -> void:
	face_direction = enabled

func fire_left():
	print("fire left")

func fire_right():
	print("fire right")
