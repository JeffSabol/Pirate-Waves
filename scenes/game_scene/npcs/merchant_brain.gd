# MerchantBrain.gd
extends Node
class_name MerchantBrain

@export var ship: ShipAI
@export var cannonball_scene: PackedScene
@export var muzzle_path: NodePath = ^"Muzzle"   # change to your muzzle node if different
@export var fire_range: float = 380.0
@export var fire_cooldown: float = 1.6
@export var aggro_duration: float = 6.0
@export var stop_to_shoot: bool = true          # if true, pause along route while firing
@export var projectile_speed: float = 420.0
@export var rotation_offset_deg: float = 90.0   # same convention as ShipAI
@export var left_fire_cooldown := 3
@export var right_fire_cooldown := 3

var _target: Node2D
var _cool: float = 0.0
var _aggro_time_left: float = 0.0
var _muzzle: Node2D
var _cruise_speed: float = 0.0

func _ready() -> void: 
	# Find components
	if ship == null:
		ship = get_parent() as ShipAI
	_muzzle = get_node_or_null(muzzle_path) as Node2D
	# Remember normal speed so we can restore it after aggro
	if ship:
		_cruise_speed = ship._speed
	# Subscribe to health events
	var h = get_parent().get_node_or_null("ShipHealth")
	if h:
		h.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	# Cooldown
	_cool = max(_cool - delta, 0.0)

	# No target? let ShipAI handle facing & speed
	if _target == null or not is_instance_valid(_target):
		_end_aggro()
		return

	# Count down aggro
	_aggro_time_left -= delta
	if _aggro_time_left <= 0.0:
		_end_aggro()
		return

	# Face target smoothly
	var to_target: Vector2 = _target.global_position - ship.global_position
	if to_target.length() > 0.1:
		var desired: float = to_target.angle() + deg_to_rad(rotation_offset_deg)
		ship.rotation = lerp_angle(ship.rotation, desired, clamp(ship.turn_speed * delta, 0.0, 1.0))

	# Optional: stop to shoot so the muzzle points steadily
	if stop_to_shoot and ship:
		ship.set_speed(0.0)
		ship.set_face_direction(false)  # prevent path-follow rotation while fighting

	# Fire if in range and off cooldown
	if to_target.length() <= fire_range:
		_try_fire(to_target)

func _on_damaged(amount: int, from: Node) -> void:
	var n2d := from as Node2D
	if n2d == null:
		return
	_target = n2d
	_aggro_time_left = aggro_duration

func _end_aggro() -> void:
	_target = null
	if ship:
		ship.set_speed(_cruise_speed)
		ship.set_face_direction(true)

func _try_fire(dir_vec: Vector2) -> void:
	if _cool > 0.0 or cannonball_scene == null:
		return
	_cool = fire_cooldown

	var spawn_at := _muzzle if _muzzle else ship
	var ball := cannonball_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(ball)
	ball.global_position = spawn_at.global_position

	# Aim/velocity — adjust to your projectile script
	# If your cannonball uses a "velocity" property:
	var v := dir_vec.normalized() * projectile_speed
	if "velocity" in ball:
		ball.velocity = v
	# If it uses speed + rotation:
	if "speed" in ball:
		ball.speed = projectile_speed
	if "rotation" in ball:
		ball.rotation = dir_vec.angle()
