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
@export var max_distance_from_player: float = 50000.0  # bump this big if you re-enable distance despawn later

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

# ---- Aggro / Chase ----
@export var chase_speed: float = 70.0
@export var aggro_preferred_range: float = 380.0   # try to hold a broadside-ish distance
@export var aggro_range_tolerance: float = 80.0    # band around preferred range

# auto-aggro-on-spawn tuning
@export var always_aggro_on_spawn: bool = true
@export var spawn_aggro_distance: float = 800.0    # if spawned farther than this, start chasing

# Debug
@export var debug_ai: bool = false

var _aggro_target: Node2D = null
var _was_aggro: bool = false   # for debug: track mode transitions

# ---- Helpers ----
func _get_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("PlayerBoat") as Node2D

func is_aggro() -> bool:
	return is_instance_valid(_aggro_target)

func set_aggro(target: Node2D) -> void:
	_aggro_target = target
	if debug_ai and target:
		print("[ShipAI]", name, "set_aggro on", target.name, " (permanent)")

func on_hit(attacker: Node) -> void:
	var p := attacker as Node2D
	if p:
		if debug_ai:
			print("[ShipAI]", name, "hit by", p.name, "-> entering aggro")
		set_aggro(p)

func _ready() -> void:
	if debug_ai:
		print("[ShipAI]", name, "READY at", global_position)

# ---- Public API ----
func set_path(curve: Curve2D, loop: bool, speed: float, start_t: float) -> void:
	_curve = curve
	_loop = loop
	_speed = speed 
	_dist = 0.0
	_length = 0.0

	if _curve:
		if override_bake_interval > 0.0:
			_curve.bake_interval = override_bake_interval
	
		_length = max(float(_curve.get_baked_length()), 0.001)
		_dist = clamp(start_t, 0.0, 1.0) * _length
		global_position = _curve.sample_baked(_dist)

		if debug_ai:
			print("[ShipAI]", name, "set_path:",
				"loop =", _loop,
				"speed =", _speed,
				"start_t =", start_t,
				"length =", _length,
				"pos =", global_position)

	# --- auto-aggro when spawned far away ---
	if always_aggro_on_spawn:
		var player := _get_player()
		if player:
			var dist_to_player := global_position.distance_to(player.global_position)
			if debug_ai:
				print("[ShipAI]", name, "spawned dist to player:", dist_to_player)
			if dist_to_player > spawn_aggro_distance:
				if debug_ai:
					print("[ShipAI]", name, "auto-aggro on spawn (permanent)")
				set_aggro(player)

func _physics_process(delta: float) -> void:
	# Optional distance despawn (kept but very high & disabled for now)
	# var player := _get_player()
	# if player and global_position.distance_to(player.global_position) > max_distance_from_player:
	# 	if debug_ai:
	# 		print("[ShipAI]", name, "despawning due to distance at", global_position)
	# 	_emit_and_free()
	# 	return

	var now_aggro := is_aggro()
	if debug_ai and now_aggro != _was_aggro:
		print("[ShipAI]", name, "mode changed to", ("AGGRO" if now_aggro else "CRUISE"))
	_was_aggro = now_aggro

	# ---- AGGRO / CHASE MODE (permanent) ----
	if now_aggro:
		if not is_instance_valid(_aggro_target):
			# Try to reacquire player if target went invalid
			var p := _get_player()
			if p:
				if debug_ai:
					print("[ShipAI]", name, "reacquiring player as aggro target")
				_aggro_target = p
			else:
				# No valid target at all -> fall back to cruise
				_aggro_target = null
				return

		var to_target: Vector2 = _aggro_target.global_position - global_position
		var dist := to_target.length()

		var lower := float(max(0.0, aggro_preferred_range - aggro_range_tolerance))
		var upper := aggro_preferred_range + aggro_range_tolerance

		var move := Vector2.ZERO
		if dist > upper:
			move = (to_target / max(1.0, dist)) * chase_speed
		elif dist < lower:
			move = -(to_target / max(1.0, dist)) * chase_speed * 0.6
		else:
			var tangent := Vector2(-to_target.y, to_target.x).normalized()
			move = tangent * chase_speed * 0.35

		global_position += move * delta

		if face_direction and move.length() > 0.001:
			var desired: float = move.angle() + deg_to_rad(rotation_offset_deg)
			var step: float = clamp(turn_speed * delta, 0.0, 1.0)
			rotation = lerp_angle(rotation, desired, step)

		_fire_if_allowed()
		return

	# ---- CRUISE MODE (path-following) ----
	if _curve == null or _length <= 0.001:
		return

	_dist += _speed * delta
	if _loop:
		_dist = fposmod(_dist, _length)
	else:
		if _dist >= _length:
			if debug_ai:
				print("[ShipAI]", name, "reached end of non-looping path, despawning.")
			_emit_and_free()
			return

	global_position = _curve.sample_baked(_dist)

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
	if is_aggro():
		if $LeftSight.is_colliding() && $LeftSight.get_collider().name == "PlayerBoat":
			if debug_ai:
				print("[ShipAI]", name, "LEFT broadside on player -> fire")
			set_aggro($LeftSight.get_collider()) # keep target fresh
			fire_left_guns()

		if $RightSight.is_colliding() && $RightSight.get_collider().name == "PlayerBoat":
			if debug_ai:
				print("[ShipAI]", name, "RIGHT broadside on player -> fire")
			set_aggro($RightSight.get_collider())
			fire_right_guns()

func _emit_and_free() -> void:
	if debug_ai:
		print("[ShipAI]", name, "despawning at", global_position)
	despawned.emit()
	queue_free()

func set_speed(speed: float) -> void:
	_speed = speed

func set_face_direction(enabled: bool) -> void:
	face_direction = enabled

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

	if debug_ai:
		print("[ShipAI]", name, "fire_left_guns")

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 1:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	var t: SceneTreeTimer = get_tree().create_timer(left_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_left = true)
		
func fire_right_guns() -> void:
	if not can_fire_right:
		return
	can_fire_right = false

	if debug_ai:
		print("[ShipAI]", name, "fire_right_guns")

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 0:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	var t: SceneTreeTimer = get_tree().create_timer(right_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_right = true)
