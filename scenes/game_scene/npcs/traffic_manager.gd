# TrafficManager.gd
extends Node

@export var merchant_scene: PackedScene
@export var pirate_scene: PackedScene
@export var activation_radius: float = 2000.0   # only routes near player spawn traffic
@export var randomize_start: bool = true        # start ships mid-route for variety

var _player: Node2D
var _routes: Array[Path2D] = [] as Array[Path2D]

# Accumulators and live counts; typed to avoid Variant warnings
var _acc: Dictionary = {}     # Path2D -> float
var _counts: Dictionary = {}  # Path2D -> int

func _ready() -> void:
	# In Godot 4.x, global RNG is already seeded; no randomize() needed/available.
	_player = get_tree().get_first_node_in_group("PlayerBoat") as Node2D

	for n in get_tree().get_nodes_in_group("TradeRoutes"):
		var route := n as Path2D
		if route and route.curve:
			_routes.append(route)
			_acc[route] = 0.0
			_counts[route] = 0

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _player == null:
		return

	for route in _routes:
		var route_node := route as Node
		var active: bool = _player.global_position.distance_to(route.global_position) <= activation_radius

		if not active:
			_acc[route] = 0.0
			continue

		var route_max := int(route_node.get("max_ships"))
		if int(_counts[route]) >= route_max:
			continue

		_acc[route] = float(_acc[route]) + delta
		var interval := float(route_node.get("spawn_interval"))
		if interval <= 0.0:
			interval = 1.0  # safety default to avoid rapid-fire spawns

		if float(_acc[route]) >= interval:
			_acc[route] = 0.0
			_spawn_on_route(route, route_node)

func _spawn_on_route(route: Path2D, route_node: Node) -> void:
	var kind := str(route_node.get("route_type")).to_lower()
	var scene: PackedScene = null

	if kind == "pirate":
		scene = pirate_scene
	elif kind == "merchant":
		scene = merchant_scene
	else:
		if (randf() < 0.5):
			scene = merchant_scene
		else:
			scene = pirate_scene

	if scene == null:
		return

	var ship := scene.instantiate() as Node2D
	get_tree().current_scene.add_child(ship)

	# Avoid hard-typing to unknown classes; check capabilities instead.
	var ship_ai := ship as Node
	if ship_ai and ship_ai.has_method("set_path"):
		var start_prog
		if (randomize_start):
			start_prog = randf()
		else:
			start_prog = 0.0
		var loop := bool(route_node.get("loop"))
		var speed := float(route_node.call("pick_speed"))
		ship_ai.call("set_path", route.curve, loop, speed, start_prog)

		if ship_ai.has_signal("despawned"):
			ship_ai.connect("despawned", Callable(self, "_on_ship_despawned").bind(route))

	_counts[route] = int(_counts[route]) + 1

func _on_ship_despawned(route: Path2D) -> void:
	if _counts.has(route):
		_counts[route] = max(0, int(_counts[route]) - 1)
