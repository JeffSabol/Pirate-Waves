extends Node
@export var ship: ShipAI
@export var detect_radius: float = 600.0
@export var chase_speed: float = 80.0
@export var fire_range: float = 400.0
@export var fire_cooldown: float = 1.2

var _player: Node2D
var _cool: float = 0.0
var _cruise_speed: float = 0.0

func _ready() -> void:
	if ship == null:
		ship = get_parent() as ShipAI
	_cruise_speed = ship._speed
	_player = get_tree().get_first_node_in_group("PlayerBoat") as Node2D

func _physics_process(delta: float) -> void:
	if _player == null: return
	_cool = max(_cool - delta, 0.0)
	var d := _player.global_position.distance_to(ship.global_position)
	if d <= detect_radius:
		ship.set_speed(chase_speed)
		ship.set_face_direction(false) # take over rotation
		var desired := (_player.global_position - ship.global_position).angle() + deg_to_rad(ship.rotation_offset_deg)
		ship.rotation = lerp_angle(ship.rotation, desired, clamp(ship.turn_speed * delta, 0.0, 1.0))
		# fire if close (reuse your firing helper)
	else:
		ship.set_speed(_cruise_speed)
		ship.set_face_direction(true)
