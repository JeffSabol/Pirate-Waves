extends Node

@export var merchant_scene: PackedScene
@export var pirate_scene: PackedScene
@export var activation_radius: float = 2000.0   # only routes near player spawn traffic
@export var randomize_start: bool = true        # keep for future use if needed
@export var spawn_avoid_radius: float = 600.0   # DO NOT spawn ships this close to the player for random spawns

var _player: Node2D
var _routes: Array[Path2D] = [] as Array[Path2D]

var _acc: Dictionary = {}     # Path2D -> float
var _counts: Dictionary = {}  # Path2D -> int

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("PlayerBoat") as Node2D
	print("TrafficManager READY. Player =", _player)

	for n in get_tree().get_nodes_in_group("TradeRoutes"):
		var route := n as Path2D
		if route and route.curve:
			_routes.append(route)
			_acc[route] = 0.0
			_counts[route] = 0
			print("  Found route:", route.name, "at", route.global_position)
		else:
			print("  Skipping node in TradeRoutes group, not a Path2D with curve:", n)

	print("Total routes tracked:", _routes.size())

	# Wave 1: spawn 4 aggressive merchants using the first route as spawn spline
	_spawn_initial_wave()

	set_physics_process(true)

func _spawn_initial_wave() -> void:
	if _player == null:
		print("[Wave1] No player; cannot spawn initial wave.")
		return
	if merchant_scene == null:
		print("[Wave1] No merchant_scene; cannot spawn initial wave.")
		return
	if _routes.is_empty():
		print("[Wave1] No routes; cannot spawn initial wave.")
		return

	var route: Path2D = _routes[0]
	var route_node: Node = route
	var curve: Curve2D = route.curve
	if curve == null:
		print("[Wave1] Route", route.name, "has no curve; cannot spawn initial wave.")
		return

	var baked_length: float = curve.get_baked_length()
	if baked_length <= 0.0:
		print("[Wave1] Route", route.name, "has baked_length <= 0; cannot spawn initial wave.")
		return

	var count := 4  # Wave 1: 4 ships
	var player := _player

	for i in range(count):
		# Evenly spaced along the route: 0.125, 0.375, 0.625, 0.875
		var start_prog: float = (float(i) + 0.5) / float(count)
		start_prog = clamp(start_prog, 0.0, 1.0)

		var distance_along := start_prog * baked_length
		var local_point: Vector2 = curve.sample_baked(distance_along)
		var world_point: Vector2 = route.to_global(local_point)

		var ship := merchant_scene.instantiate() as Node2D
		get_tree().current_scene.add_child.call_deferred(ship)
		ship.global_position = world_point

		print(
			"[Wave1] Spawned merchant", i,
			"at", world_point,
			"start_prog:", start_prog
		)

		# IMPORTANT: Wave 1 ships use the route only as spawn positions.
		# They do NOT follow the route; they just aggro on the player.
		var ship_ai := ship as ShipAI
		if ship_ai and player:
			ship_ai.set_aggro(player)
		else:
			print("[Wave1] Spawned ship has no ShipAI or no player:", ship)

	# Track counts so later spawns respect max_ships for this route
	_counts[route] = int(_counts.get(route, 0)) + count
	print("[Wave1] Route", route.name, "now has", _counts[route], "ships after initial wave.")

func _physics_process(delta: float) -> void:
	if _player == null:
		return

	for route in _routes:
		var route_node := route as Node

		var active: bool = _player.global_position.distance_to(route.global_position) <= activation_radius
		# DEBUG:
		# print("Route", route.name, "active?", active)

		if not active:
			_acc[route] = 0.0
			continue

		var route_max := int(route_node.get("max_ships"))
		if int(_counts[route]) >= route_max:
			# print("Route", route.name, "at max ships:", route_max)
			continue

		_acc[route] = float(_acc[route]) + delta
		var interval := float(route_node.get("spawn_interval"))
		if interval <= 0.0:
			interval = 1.0

		if float(_acc[route]) >= interval:
			_acc[route] = 0.0
			print("Attempting spawn on route", route.name, "current count:", _counts[route])
			_spawn_on_route(route, route_node)

func _spawn_on_route(route: Path2D, route_node: Node) -> void:
	var kind := str(route_node.get("route_type")).to_lower()
	var scene: PackedScene = null

	if kind == "pirate":
		scene = pirate_scene
	elif kind == "merchant":
		scene = merchant_scene
	else:
		scene = merchant_scene if randf() < 0.5 else pirate_scene

	if scene == null:
		print("No scene set for route", route.name, "type:", kind)
		return

	var curve := route.curve
	if curve == null:
		print("Route", route.name, "has no curve!")
		return

	var baked_length := curve.get_baked_length()
	if baked_length <= 0.0:
		print("Route", route.name, "has baked_length <= 0")
		return

	var start_prog: float = 0.0
	var found_safe_spot := false
	var max_tries := 8
	var spawn_world_point: Vector2 = Vector2.ZERO

	while max_tries > 0 and not found_safe_spot:
		var candidate_prog := randf()
		var distance_along := candidate_prog * baked_length

		var local_point: Vector2 = curve.sample_baked(distance_along)
		var world_point: Vector2 = route.to_global(local_point)
		var dist_to_player := world_point.distance_to(_player.global_position)

		# DEBUG:
		# print("  Candidate on", route.name, "at", world_point, "dist to player:", dist_to_player)

		if dist_to_player > spawn_avoid_radius:
			start_prog = candidate_prog
			spawn_world_point = world_point
			found_safe_spot = true
		else:
			max_tries -= 1

	if not found_safe_spot:
		print("Could not find safe spawn spot on route", route.name, "after tries")
		return

	var ship := scene.instantiate() as Node2D
	get_tree().current_scene.add_child(ship)

	# Snap to the chosen world spawn position
	ship.global_position = spawn_world_point

	print(
		"Spawned", kind, "ship on route", route.name,
		"at", spawn_world_point,
		"distance to player:", spawn_world_point.distance_to(_player.global_position),
		"start_prog:", start_prog
	)

	var ship_ai := ship as Node
	if ship_ai and ship_ai.has_method("set_path"):
		var loop := bool(route_node.get("loop"))
		var speed := float(route_node.call("pick_speed"))

		ship_ai.call("set_path", curve, loop, speed, start_prog)

		if ship_ai.has_signal("despawned"):
			ship_ai.connect("despawned", Callable(self, "_on_ship_despawned").bind(route))
	else:
		print("Spawned ship does not have set_path method:", ship)

	_counts[route] = int(_counts[route]) + 1
	print("Route", route.name, "now has", _counts[route], "ships")

func _on_ship_despawned(route: Path2D) -> void:
	if _counts.has(route):
		_counts[route] = max(0, int(_counts[route]) - 1)
		print("Ship despawned from route", route.name, "remaining:", _counts[route])
