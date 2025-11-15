extends Node
class_name WaveManager
# Wave-based spawner that uses trade routes as spawn splines.

# Enemy scenes (set these in the inspector)
@export var sloop_scene: PackedScene
@export var corsair_scene: PackedScene
@export var brig_scene: PackedScene
@export var boss_scene: PackedScene

# How far from the player we try to keep spawns
@export var spawn_avoid_radius: float = 600.0

# Delay between clearing a wave and starting the next (seconds)
@export var wave_delay: float = 2.0

var _player: Node2D
var _routes: Array[Path2D] = [] as Array[Path2D]

var _current_wave: int = 1
var _enemies_alive: int = 0
var _waves_started: bool = false

# 5-wave pattern that repeats; counts are base values for wave 1–5.
# Higher waves will scale these up.
const BASE_WAVE_PATTERN: Array[Dictionary] = [
	{ "sloop": 3, "corsair": 0, "brig": 0, "boss": false }, # Wave 1
	{ "sloop": 4, "corsair": 1, "brig": 0, "boss": false }, # Wave 2
	{ "sloop": 5, "corsair": 2, "brig": 0, "boss": false }, # Wave 3
	{ "sloop": 6, "corsair": 2, "brig": 1, "boss": false }, # Wave 4
	{ "sloop": 6, "corsair": 3, "brig": 2, "boss": true  }, # Wave 5 (boss)
]


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("PlayerBoat") as Node2D
	print("[WaveManager] READY. Player =", _player)

	for n in get_tree().get_nodes_in_group("TradeRoutes"):
		var route := n as Path2D
		if route and route.curve:
			_routes.append(route)
			print("  Found route:", route.name, "at", route.global_position)
		else:
			print("  Skipping node in TradeRoutes group, not a Path2D with curve:", n)

	print("[WaveManager] Total routes tracked:", _routes.size())
	# IMPORTANT: we DO NOT start waves here anymore.
	# Town will explicitly call start_waves() when the player leaves.


# ------------------------
# PUBLIC API – called by Town
# ------------------------

func start_waves() -> void:
	if _waves_started:
		return
	_waves_started = true
	print("[WaveManager] Waves started by town trigger. Starting wave", _current_wave)
	_start_wave(_current_wave)


# ------------------------
# WAVE LOGIC
# ------------------------

func _start_wave(wave: int) -> void:
	if _player == null:
		print("[WaveManager] No player; cannot start wave", wave)
		return

	if BASE_WAVE_PATTERN.is_empty():
		print("[WaveManager] BASE_WAVE_PATTERN is empty; cannot start wave.")
		return

	var pattern_index: int = (wave - 1) % BASE_WAVE_PATTERN.size()
	var cycle: int = int((wave - 1) / BASE_WAVE_PATTERN.size())  # 0 for waves 1–5, 1 for 6–10, etc.

	var base: Dictionary = BASE_WAVE_PATTERN[pattern_index]

	# Increase difficulty each 5-wave cycle
	var multiplier: float = 1.0 + float(cycle) * 0.5  # +50% enemies each cycle

	var num_sloop: int = int(ceil(float(base["sloop"]) * multiplier))
	var num_corsair: int = int(ceil(float(base["corsair"]) * multiplier))
	var num_brig: int = int(ceil(float(base["brig"]) * multiplier))
	var has_boss: bool = bool(base["boss"])

	print("\n[WaveManager] Starting wave", wave,
		"cycle =", cycle,
		"multiplier =", multiplier,
		"sloop =", num_sloop,
		"corsair =", num_corsair,
		"brig =", num_brig,
		"boss =", has_boss)

	var enemies_to_spawn: Array[PackedScene] = []

	if sloop_scene:
		for i in range(num_sloop):
			enemies_to_spawn.append(sloop_scene)

	if corsair_scene:
		for i in range(num_corsair):
			enemies_to_spawn.append(corsair_scene)

	if brig_scene:
		for i in range(num_brig):
			enemies_to_spawn.append(brig_scene)

	if has_boss and boss_scene:
		enemies_to_spawn.append(boss_scene)

	if enemies_to_spawn.is_empty():
		print("[WaveManager] No enemy scenes assigned; wave has nothing to spawn.")
		return

	# Pick spawn positions for all enemies
	var spawn_positions: Array[Vector2] = _pick_spawn_positions(enemies_to_spawn.size())

	_enemies_alive = 0

	for i in range(enemies_to_spawn.size()):
		var scene: PackedScene = enemies_to_spawn[i]
		var pos: Vector2 = spawn_positions[i]
		_spawn_enemy(scene, pos)

	print("[WaveManager] Wave", wave, "spawned", _enemies_alive, "enemies.")


func _spawn_enemy(scene: PackedScene, position: Vector2) -> void:
	if scene == null:
		return

	var ship := scene.instantiate() as Node2D
	if ship == null:
		return

	# Use deferred add_child to avoid "SceneTree is busy" errors
	var root: Node = get_tree().current_scene
	if root == null:
		root = self
	root.call_deferred("add_child", ship)

	ship.global_position = position

	var ship_ai := ship as ShipAI
	if ship_ai and _player:
		ship_ai.set_aggro(_player)  # permanent chase in your current ShipAI

		_enemies_alive += 1
		if ship_ai.has_signal("despawned"):
			ship_ai.despawned.connect(Callable(self, "_on_enemy_despawned"))
	else:
		print("[WaveManager] Spawned ship has no ShipAI or no player:", ship)


func _on_enemy_despawned() -> void:
	_enemies_alive = max(0, _enemies_alive - 1)
	print("[WaveManager] Enemy despawned. Remaining:", _enemies_alive)

	if _enemies_alive == 0:
		_current_wave += 1
		print("[WaveManager] Wave cleared! Next wave:", _current_wave)
		var t: SceneTreeTimer = get_tree().create_timer(wave_delay)
		t.timeout.connect(func() -> void:
			_start_wave(_current_wave))


# ------------------------
# SPAWN POSITION LOGIC
# ------------------------

func _pick_spawn_positions(count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count <= 0:
		return result

	# If we have at least one route, use the first as a spawn spline.
	if not _routes.is_empty():
		var route: Path2D = _routes[0]
		var curve: Curve2D = route.curve

		if curve:
			var baked_length: float = curve.get_baked_length()
			if baked_length > 0.0:
				for i in range(count):
					var prog: float = (float(i) + 0.5) / float(count)  # 0.5/N, 1.5/N, ...
					prog = clamp(prog, 0.0, 1.0)

					var dist_along: float = prog * baked_length
					var local_point: Vector2 = curve.sample_baked(dist_along)
					var world_point: Vector2 = route.to_global(local_point)

					if _player and world_point.distance_to(_player.global_position) < spawn_avoid_radius:
						var dir: Vector2 = (world_point - _player.global_position).normalized()
						world_point = _player.global_position + dir * spawn_avoid_radius

					result.append(world_point)

				return result

	# Fallback: spawn in a ring around the player
	var center: Vector2 = Vector2.ZERO
	if _player:
		center = _player.global_position

	var radius: float = 800.0

	for i in range(count):
		var angle: float = TAU * float(i) / float(max(1, count))
		var pos: Vector2 = center + Vector2(radius, 0.0).rotated(angle)
		result.append(pos)

	return result
