extends CharacterBody2D
class_name BossAI

signal despawned

# NOTE:
# This AI does NOT follow Path2D/Curve2D.
# set_path() is ONLY used to place the ship at spawn time based on a route.
# After spawning, movement is purely chase + orbit around the player.

# ---- Tuning ----
@export var max_distance_from_player: float = 50000.0

# Facing controls
@export var face_direction: bool = true
@export var turn_speed: float = 6.0
@export var rotation_offset_deg: float = 90.0

# Cannons
@export var left_fire_cooldown: float = 3.0
@export var right_fire_cooldown: float = 3.0
var can_fire_left: bool = true
var can_fire_right: bool = true
@export var guns: int = 12   # BOSS: 12 guns by default

# ---- Aggro / Chase ----
@export var chase_speed: float = 70.0
@export var aggro_preferred_range: float = 380.0   # orbit radius
@export var aggro_range_tolerance: float = 80.0
@export var orbit_clockwise: bool = true

# Boss: always aggro the player as soon as possible, no distance checks.
@export var always_aggro_player: bool = true

# Death / FX
@export var death_fade_time: float = 1.0  # seconds

# Debug
@export var debug_ai: bool = false

var _aggro_target: Node2D = null
var _was_aggro: bool = false
var _is_dying: bool = false
var _has_been_hurt: bool = false

# Ghosts
@export var ghost_ship_scene: PackedScene
@export var ghost_health_threshold: float = 0.75
@export var ghost_ships_to_spawn: int = 2

var _ghosts_spawned: bool = false

# ---- Helpers ----
func _get_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null

	# Prefer group "player"
	var p := tree.get_first_node_in_group("player")
	if p:
		return p as Node2D

	# Fallback: group "PlayerBoat"
	p = tree.get_first_node_in_group("PlayerBoat")
	if p:
		return p as Node2D

	# Fallback: by name
	var scene := tree.current_scene
	if scene:
		var by_name := scene.get_node_or_null("PlayerBoat")
		if by_name:
			return by_name as Node2D
		var found := scene.find_child("PlayerBoat", true, false)
		if found:
			return found as Node2D

	return null


func is_aggro() -> bool:
	return is_instance_valid(_aggro_target)


func set_aggro(target: Node2D) -> void:
	_aggro_target = target
	if debug_ai and target:
		print("[BossAI]", name, "set_aggro on", target.name, " (permanent)")


func _play_hurt_state() -> void:
	if _has_been_hurt:
		return
	_has_been_hurt = true
	if has_node("AnimatedSprite2D"):
		var anim: AnimatedSprite2D = $AnimatedSprite2D
		if anim:
			var names: PackedStringArray = anim.sprite_frames.get_animation_names()
			if "hurt" in names:
				anim.play("hurt")
			if debug_ai:
				print("[BossAI]", name, "entered HURT state")


func on_hit(attacker: Node) -> void:
	var p := attacker as Node2D
	if p:
		if debug_ai:
			print("[BossAI]", name, "hit by", p.name, "-> entering aggro")
		set_aggro(p)
	_play_hurt_state()


func _ready() -> void:
	if debug_ai:
		print("[BossAI]", name, "READY at", global_position)

	update_guns_visibility()

	# BOSS BEHAVIOR: as soon as we exist, try to aggro the player.
	if always_aggro_player:
		var player := _get_player()
		if player:
			if debug_ai:
				print("[BossAI]", name, "auto-aggro on READY to", player.name)
			set_aggro(player)


# ---- Public API ----
# Only used to choose a spawn point along the route
func set_path(curve: Curve2D, loop: bool, speed: float, start_t: float) -> void:
	if curve:
		var length: float = max(float(curve.get_baked_length()), 0.001)
		var dist: float = clamp(start_t, 0.0, 1.0) * length
		global_position = curve.sample_baked(dist)

		if debug_ai:
			print("[BossAI]", name, "set_path spawn:",
				"start_t =", start_t,
				"length =", length,
				"pos =", global_position)

	# BOSS: regardless of spawn distance, always aggro the player
	if always_aggro_player:
		var player := _get_player()
		if player:
			if debug_ai:
				print("[BossAI]", name, "auto-aggro on SPAWN to", player.name)
			set_aggro(player)


# Call this when HP <= 0 instead of queue_free()
func begin_death() -> void:
	if _is_dying:
		if debug_ai:
			print("[BossAI]", name, "begin_death() called AGAIN but already dying")
		return

	_is_dying = true
	if debug_ai:
		print("\n========== BOSSAI DEATH START ==========")
		print("[BossAI]", name, "begin_death; switching sprite to 'defeated'")

	can_fire_left = false
	can_fire_right = false
	velocity = Vector2.ZERO

	if has_node("AnimatedSprite2D"):
		var anim: AnimatedSprite2D = $AnimatedSprite2D
		if debug_ai:
			print("[BossAI]", name, "AnimatedSprite2D found; checking animations...")
		if anim and anim.sprite_frames:
			var names: PackedStringArray = anim.sprite_frames.get_animation_names()
			if debug_ai:
				print("[BossAI]", name, "animations:", names)
			if "defeated" in names:
				if debug_ai:
					print("[BossAI]", name, "PLAYING 'defeated' animation now")
				anim.animation = "defeated"
				anim.frame = 0
				anim.play()
			elif "hurt" in names:
				if debug_ai:
					print("[BossAI]", name, "NO 'defeated' animation, using 'hurt'")
				anim.animation = "hurt"
				anim.frame = 0
				anim.play()

	_start_death_fade()


func _start_death_fade() -> void:
	if debug_ai:
		print("[BossAI]", name, "_start_death_fade entered")
	var fade_time: float = max(0.0, death_fade_time)

	if fade_time == 0.0:
		if debug_ai:
			print("[BossAI]", name, "fade_time=0 -> instant despawn")
		_emit_and_free()
		return

	var tween := get_tree().create_tween()
	if tween == null:
		print("[BossAI]", name, "ERROR: tween is NULL!!")
		_emit_and_free()
		return

	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.finished.connect(func() -> void:
		if debug_ai:
			print("[BossAI]", name, "FADE COMPLETE — now removing ship")
		_emit_and_free())


func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var now_aggro: bool = is_aggro()

	# If we somehow lost the target, re-acquire the player and KEEP CHASING.
	if not now_aggro and always_aggro_player:
		var player := _get_player()
		if player:
			if debug_ai:
				print("[BossAI]", name, "reacquired player, staying aggro")
			set_aggro(player)
			now_aggro = true

	if debug_ai and now_aggro != _was_aggro:
		print("[BossAI]", name, "mode changed to", ("AGGRO" if now_aggro else "IDLE"))
	_was_aggro = now_aggro

	if now_aggro:
		velocity = _compute_aggro_velocity(delta)
		_fire_if_allowed()
	else:
		velocity = Vector2.ZERO

	move_and_slide()


# ---- AGGRO BEHAVIOR (CHASE + ORBIT) ----
func _compute_aggro_velocity(delta: float) -> Vector2:
	if not is_instance_valid(_aggro_target):
		# Boss should *always* try to re-lock on player.
		var p := _get_player()
		if p:
			if debug_ai:
				print("[BossAI]", name, "reacquiring player as aggro target")
			_aggro_target = p
		else:
			_aggro_target = null
			return Vector2.ZERO

	var target_pos: Vector2 = _aggro_target.global_position
	var to_target: Vector2 = target_pos - global_position
	var dist: float = to_target.length()
	if dist <= 1.0:
		return Vector2.ZERO

	var forward: Vector2 = to_target / dist

	var desired_radius: float = aggro_preferred_range
	var radius_error: float = dist - desired_radius

	var tangent: Vector2 = Vector2(-forward.y, forward.x)
	if not orbit_clockwise:
		tangent = -tangent
	tangent = tangent.normalized()

	var radial_factor: float = clamp(radius_error / max(1.0, aggro_preferred_range), -1.0, 1.0)
	var radial: Vector2 = forward * radial_factor

	var tangent_weight: float = 1.0
	var radial_weight: float = 0.6
	if abs(radius_error) < aggro_range_tolerance * 0.5:
		radial_weight *= 0.25

	var move_dir: Vector2 = (tangent * tangent_weight + radial * radial_weight).normalized()
	if face_direction and move_dir.length() > 0.001:
		var desired_angle: float = move_dir.angle() + deg_to_rad(rotation_offset_deg)
		var step: float = clamp(turn_speed * delta, 0.0, 1.0)
		rotation = lerp_angle(rotation, desired_angle, step)

	return move_dir * chase_speed


# ---- FIRING ----
func _fire_if_allowed() -> void:
	if not is_aggro() or _is_dying:
		return

	# LEFT
	var left_collider = $LeftSight.get_collider()
	if $LeftSight.is_colliding() and left_collider and is_instance_valid(left_collider):
		if left_collider.name == "PlayerBoat":
			if debug_ai:
				print("[BossAI]", name, "LEFT broadside on player -> fire")
			set_aggro(left_collider)
			fire_left_guns()

	# LEFT
	var left_collider2 = $LeftSight2.get_collider()
	if $LeftSight2.is_colliding() and left_collider2 and is_instance_valid(left_collider2):
		if left_collider2.name == "PlayerBoat":
			if debug_ai:
				print("[BossAI]", name, "LEFT broadside on player -> fire")
			set_aggro(left_collider2)
			fire_left_guns()


	# RIGHT
	var right_collider = $RightSight.get_collider()
	if $RightSight.is_colliding() and right_collider and is_instance_valid(right_collider):
		if right_collider.name == "PlayerBoat":
			if debug_ai:
				print("[BossAI]", name, "RIGHT broadside on player -> fire")
			set_aggro(right_collider)
			fire_right_guns()

	# RIGHT
	var right_collider2 = $RightSight2.get_collider()
	if $RightSight2.is_colliding() and right_collider2 and is_instance_valid(right_collider2):
		if right_collider2.name == "PlayerBoat":
			if debug_ai:
				print("[BossAI]", name, "RIGHT broadside on player -> fire")
			set_aggro(right_collider2)
			fire_right_guns()


func _emit_and_free() -> void:
	if debug_ai:
		print("[BossAI]", name, "despawning at", global_position)
	despawned.emit()
	queue_free()


func set_speed(speed: float) -> void:
	chase_speed = speed


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
	if not can_fire_left or _is_dying:
		return
	can_fire_left = false

	if debug_ai:
		print("[BossAI]", name, "fire_left_guns")

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 0:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	var t: SceneTreeTimer = get_tree().create_timer(left_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_left = true)


func fire_right_guns() -> void:
	if not can_fire_right or _is_dying:
		return
	can_fire_right = false

	if debug_ai:
		print("[BossAI]", name, "fire_right_guns")

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 1:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	var t: SceneTreeTimer = get_tree().create_timer(right_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_right = true)

func _check_spawn_ghosts() -> void:
	if _ghosts_spawned:
		return

	if ghost_ship_scene == null:
		return

	var health_ratio: float = $BossHealth.hp / $BossHealth.max_hp

	if health_ratio <= ghost_health_threshold:
		_ghosts_spawned = true
		_spawn_ghost_ships()

func _spawn_ghost_ships() -> void:
	if ghost_ship_scene == null:
		return

	var tree := get_tree()
	if tree == null:
		return

	# Find the player the same way ShipAI does
	var player := tree.get_first_node_in_group("PlayerBoat") as Node2D

	for i in range(ghost_ships_to_spawn):
		var ghost := ghost_ship_scene.instantiate()
		ghost.global_position = global_position + Vector2(
			randf_range(-120, 120),
			randf_range(-120, 120)
		)

		# If this ghost uses ShipAI, give it a target so it starts in AGGRO
		if player and ghost is ShipAI:
			ghost.set_aggro(player)

		# Safe to defer add_child because of physics
		tree.current_scene.call_deferred("add_child", ghost)
