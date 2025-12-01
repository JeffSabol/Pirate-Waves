extends Control

@onready var player: Node2D     = $"../../../PlayerBoat"
@onready var world_root: Node2D = $"../../../"

@onready var holder: TextureRect = $Holder
@onready var arrow:  TextureRect = $Arrow

const DEBUG: bool = true

const ENEMY_NAME_PREFIXES := [
	"SloopShip",
	"BrigShip",
	"BossShip",
	"CorsairShip",
	"GhostShip"
]

# Spring / wobble tuning
const SPRING_STIFFNESS: float = 16.0  # how strongly it tries to face the target
const SPRING_DAMPING: float   = 6.0   # how quickly it calms down (higher = less wobble)

var _last_nearest: Node2D = null
var _printed_children_once: bool = false
var _printed_no_world_once: bool = false

var _needle_velocity: float = 0.0   # angular velocity (radians/sec)


func _ready() -> void:
	if DEBUG:
		print("\n[Compass] _ready()")
		print("[Compass] player =", player)
		print("[Compass] world_root =", world_root)

	# Wait until both have a valid size
	await holder.resized
	await arrow.resized

	# 1) Center the arrow on top of the holder
	arrow.position = holder.position + holder.size * 0.5 - arrow.size * 0.5

	# 2) Rotate around the center of the arrow (31x31 -> (15.5, 15.5))
	# (Probably redundant) Should already be set in the inspector...
	arrow.pivot_offset = arrow.size * 0.5

	if DEBUG:
		print("[Compass] Holder size =", holder.size, " pos =", holder.position)
		print("[Compass] Arrow size  =", arrow.size,  " pos =", arrow.position,
			" pivot_offset =", arrow.pivot_offset)

	# 3) Arrow always visible; it just won’t rotate if no enemy
	arrow.visible = true


func _process(delta: float) -> void:
	# === Hide entire compass until the player owns it ===
	if not player.has_compass:
		visible = false
		return
	else:
		visible = true

	if !is_instance_valid(player):
		if DEBUG:
			print("[Compass] No valid player; skipping update.")
		return

	if !is_instance_valid(world_root):
		if DEBUG and !_printed_no_world_once:
			_printed_no_world_once = true
			print("[Compass] world_root is invalid or null in _process().")
		return

	if DEBUG and !_printed_children_once:
		_printed_children_once = true
		print("[Compass] Listing direct children of world_root:", world_root.name)
		for child in world_root.get_children():
			print("  [Compass] Child:", child.name, " (", child.get_class(), ")",
				" is_enemy_ship=", _is_enemy_ship(child))

	var nearest_enemy: Node2D = _get_nearest_enemy()
	if nearest_enemy == null:
		# No enemy? Let the needle slowly settle / stay where it is.
		return

	var dir: Vector2 = nearest_enemy.global_position - player.global_position
	var raw_angle: float = dir.angle()

	# Arrow texture points UP in the sprite, and we want the RED tip to point at the enemy.
	# We previously used -90; flipping to +90 rotates it 180°, so red points instead of blue.
	var target_angle: float = raw_angle + deg_to_rad(90.0)
	# If it's still backwards for some reason, swap + for - above.

	# ---- spring / wobble compass behavior ----
	var diff: float = wrapf(target_angle - arrow.rotation, -PI, PI)

	# Spring-damper:
	# accel ≈ diff * stiffness - vel * damping
	_needle_velocity += diff * SPRING_STIFFNESS * delta
	_needle_velocity -= _needle_velocity * SPRING_DAMPING * delta

	# Integrate
	arrow.rotation += _needle_velocity * delta

	if DEBUG and nearest_enemy != _last_nearest:
		_last_nearest = nearest_enemy
		print("[Compass] New nearest enemy:", nearest_enemy.name,
			" dist=", player.global_position.distance_to(nearest_enemy.global_position),
			" raw_angle(rad)=", raw_angle,
			" target_angle(rad)=", target_angle,
			" arrow.rotation(rad)=", arrow.rotation,
			" vel=", _needle_velocity)


func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best_dist: float = INF

	# DFS
	var stack: Array[Node] = [world_root]

	while stack.size() > 0:
		var node: Node = stack.pop_back()

		for child in node.get_children():
			stack.push_back(child)

			if child is Node2D and _is_enemy_ship(child):
				var enemy: Node2D = child as Node2D
				var d: float = player.global_position.distance_to(enemy.global_position)
				if d < best_dist:
					best_dist = d
					nearest = enemy

	return nearest


func _is_enemy_ship(node: Node) -> bool:
	for prefix in ENEMY_NAME_PREFIXES:
		if node.name.begins_with(prefix):
			return true
	return false
