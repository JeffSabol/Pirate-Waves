extends Path2D
#class_name TradeRoute

@export_enum("merchant", "pirate", "mixed") var route_type: String = "merchant"
@export var max_ships: int = 3
@export var spawn_interval: float = 8.0
@export var loop: bool = true
@export var min_speed: float = 30.0
@export var max_speed: float = 60.0

func _ready() -> void:
	add_to_group("trade_routes")

func pick_speed() -> float:
	return randf_range(min_speed, max_speed)
