extends Node
# Wave-based spawner that uses trade routes as spawn splines.
# Waves ONLY start when the town tells us (player leaves town).

# Enemy scenes (set these in the inspector)
@export var sloop_scene: PackedScene
@export var corsair_scene: PackedScene
@export var brig_scene: PackedScene
@export var boss_scene: PackedScene

# How far from the player we try to keep spawns
@export var spawn_avoid_radius: float = 600.0

# Debug
@export var debug_waves: bool = false

var _player: Node2D
var _routes: Array[Path2D] = [] as Array[Path2D]

var _current_wave: int = 0               # starts at 0; first town exit -> wave 1
@export var wave_active: bool = false
var _enemies_alive: int = 0

var _enemies_remaining_total: int = 0
var _enemies_remaining_per_type: Dictionary = {
	"sloop": 0,
	"corsair": 0,
	"brig": 0,
	"boss": 0,
}

var _awaiting_return_to_town: bool = false

signal wave_finished

const BASE_WAVE_PATTERN: Array[Dictionary] = [
	# ---- Early Game: Onboarding (1–5) ----
	{ "sloop": 3, "corsair": 0, "brig": 0, "boss": false }, # Wave 1
	{ "sloop": 4, "corsair": 1, "brig": 0, "boss": false }, # Wave 2
	{ "sloop": 5, "corsair": 2, "brig": 0, "boss": false }, # Wave 3
	{ "sloop": 6, "corsair": 2, "brig": 1, "boss": false }, # Wave 4
	{ "sloop": 6, "corsair": 3, "brig": 2, "boss": true  }, # Wave 5 (Boss 1)

	# ---- Tier 2: More Corsairs, First Real Spike (6–10) ----
	{ "sloop": 7, "corsair": 3, "brig": 2, "boss": false }, # Wave 6
	{ "sloop": 8, "corsair": 4, "brig": 2, "boss": false }, # Wave 7
	{ "sloop": 8, "corsair": 4, "brig": 3, "boss": false }, # Wave 8
	{ "sloop": 9, "corsair": 5, "brig": 3, "boss": false }, # Wave 9
	{ "sloop": 9, "corsair": 5, "brig": 4, "boss": true  }, # Wave 10 (Boss 2)

	# ---- Tier 3: Shift Toward Heavier Ships (11–15) ----
	{ "sloop": 8, "corsair": 6, "brig": 4, "boss": false }, # Wave 11
	{ "sloop": 8, "corsair": 6, "brig": 5, "boss": false }, # Wave 12
	{ "sloop": 9, "corsair": 7, "brig": 5, "boss": false }, # Wave 13
	{ "sloop": 9, "corsair": 7, "brig": 6, "boss": false }, # Wave 14
	{ "sloop": 10, "corsair": 8, "brig": 6, "boss": true }, # Wave 15 (Boss 3)

	# ---- Tier 4: Brig City (16–20) ----
	{ "sloop": 8, "corsair": 8, "brig": 6, "boss": false }, # Wave 16 (slight breather after boss)
	{ "sloop": 8, "corsair": 9, "brig": 7, "boss": false }, # Wave 17
	{ "sloop": 9, "corsair": 9, "brig": 7, "boss": false }, # Wave 18
	{ "sloop": 9, "corsair": 10, "brig": 8, "boss": false }, # Wave 19
	{ "sloop": 10, "corsair": 10, "brig": 8, "boss": true }, # Wave 20 (Boss 4)

	# ---- Tier 5: Endgame Gauntlet (21–25) ----
	{ "sloop": 10, "corsair": 10, "brig": 9, "boss": false }, # Wave 21
	{ "sloop": 10, "corsair": 11, "brig": 9, "boss": false }, # Wave 22
	{ "sloop": 11, "corsair": 11, "brig": 9, "boss": false }, # Wave 23
	{ "sloop": 11, "corsair": 12, "brig": 10, "boss": false }, # Wave 24
	{ "sloop": 12, "corsair": 12, "brig": 10, "boss": true }, # Wave 25 (Boss 5 - Finale)
]

# ---- Signals for HUD ----
signal wave_started(wave: int, total: int, per_type: Dictionary)
signal enemy_counts_changed(total: int, per_type: Dictionary)
signal wave_cleared(wave: int)


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
	print("[WaveManager] Waiting for town to start first wave (request_start_wave_from_town())")


# PUBLIC: called from town when player leaves
func request_start_wave_from_town() -> void:
	if wave_active:
		if debug_waves:
			print("[WaveManager] request_start_wave_from_town ignored; wave already active:", _current_wave)
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("PlayerBoat") as Node2D

	if _player == null:
		print("[WaveManager] No player; cannot start wave.")
		return

	_awaiting_return_to_town = false
	_current_wave += 1

	if debug_waves:
		print("\n[WaveManager] Town requested wave start. Starting wave", _current_wave)

	_start_wave(_current_wave)
	_play_wave_start_sfx(_current_wave, _current_wave % 5 == 0)


# ------------------------
# WAVE LOGIC
# ------------------------
func _start_wave(wave: int) -> void:
	ProjectMusicController.play_stream(load("res://assets/sfx/LOOP_WavesPiratesLife.wav"))
	
	if BASE_WAVE_PATTERN.is_empty():
		print("[WaveManager] BASE_WAVE_PATTERN is empty; cannot start wave.")
		return

	if _routes.is_empty():
		print("[WaveManager] WARNING: no routes; will spawn in ring around player.")
	
	var pattern_index: int = (wave - 1) % BASE_WAVE_PATTERN.size()
	var cycle: int = int((wave - 1) / BASE_WAVE_PATTERN.size())  # 0 for waves 1–5, 1 for 6–10, etc.

	var base: Dictionary = BASE_WAVE_PATTERN[pattern_index]

	# Increase difficulty each 5-wave cycle
	var multiplier: float = 1.0 + float(cycle) * 0.5  # +50% enemies each cycle

	var num_sloop: int = int(ceil(float(base["sloop"]) * multiplier))
	var num_corsair: int = int(ceil(float(base["corsair"]) * multiplier))
	var num_brig: int = int(ceil(float(base["brig"]) * multiplier))
	var has_boss: bool = bool(base["boss"])

	if debug_waves:
		print("\n[WaveManager] Starting wave", wave,
			"cycle =", cycle,
			"multiplier =", multiplier,
			"sloop =", num_sloop,
			"corsair =", num_corsair,
			"brig =", num_brig,
			"boss =", has_boss)

	var enemies_to_spawn: Array[Dictionary] = []   # { "scene": PackedScene, "kind": String }

	if sloop_scene:
		for i in range(num_sloop):
			enemies_to_spawn.append({ "scene": sloop_scene, "kind": "sloop" })

	if corsair_scene:
		for i in range(num_corsair):
			enemies_to_spawn.append({ "scene": corsair_scene, "kind": "corsair" })

	if brig_scene:
		for i in range(num_brig):
			enemies_to_spawn.append({ "scene": brig_scene, "kind": "brig" })

	if has_boss and boss_scene:
		enemies_to_spawn.append({ "scene": boss_scene, "kind": "boss" })

	if enemies_to_spawn.is_empty():
		print("[WaveManager] No enemy scenes assigned; wave has nothing to spawn.")
		return

	# Track counts
	_enemies_remaining_per_type["sloop"] = num_sloop
	_enemies_remaining_per_type["corsair"] = num_corsair
	_enemies_remaining_per_type["brig"] = num_brig
	var boss_count := 0
	if has_boss:
		boss_count = 1

	_enemies_remaining_per_type["boss"] = boss_count
	_enemies_remaining_total = num_sloop + num_corsair + num_brig + boss_count

	_enemies_alive = _enemies_remaining_total
	wave_active = true

	# Pick spawn positions for all enemies
	var spawn_positions: Array[Vector2] = _pick_spawn_positions(enemies_to_spawn.size())

	for i in range(enemies_to_spawn.size()):
		var info: Dictionary = enemies_to_spawn[i]
		var scene: PackedScene = info["scene"]
		var kind: String = info["kind"]
		var pos: Vector2 = spawn_positions[i]
		_spawn_enemy(scene, pos, kind)

	print("[WaveManager] Wave", wave, "spawned", _enemies_alive, "enemies.")

	# Let HUD know
	wave_started.emit(wave, _enemies_remaining_total, _enemies_remaining_per_type.duplicate(true))
	enemy_counts_changed.emit(_enemies_remaining_total, _enemies_remaining_per_type.duplicate(true))
	call_deferred("_update_hud")


func _spawn_enemy(scene: PackedScene, position: Vector2, kind: String) -> void:
	if scene == null:
		return

	var ship := scene.instantiate() as Node2D
	if ship == null:
		return

	var root: Node = get_tree().current_scene
	if root == null:
		root = self
	root.call_deferred("add_child", ship)
	ship.global_position = position

	var ship_ai := ship as ShipAI
	if ship_ai and _player:
		ship_ai.set_aggro(_player)

		# Connect despawn signal with enemy type
		if ship_ai.has_signal("despawned"):
			ship_ai.despawned.connect(Callable(self, "_on_enemy_despawned").bind(kind))
	else:
		print("[WaveManager] Spawned ship has no ShipAI or no player:", ship)


func _on_enemy_despawned(kind: String) -> void:
	call_deferred("_update_hud")
	if not wave_active:
		return

	_enemies_alive = max(0, _enemies_alive - 1)
	_enemies_remaining_total = max(0, _enemies_remaining_total - 1)

	if _enemies_remaining_per_type.has(kind):
		_enemies_remaining_per_type[kind] = max(0, int(_enemies_remaining_per_type[kind]) - 1)

	if debug_waves:
		print("[WaveManager] Enemy of type", kind, "despawned. Remaining total:", _enemies_remaining_total)

	enemy_counts_changed.emit(_enemies_remaining_total, _enemies_remaining_per_type.duplicate(true))

	if _enemies_remaining_total == 0:
		wave_active = false
		_awaiting_return_to_town = true
		print("[WaveManager] Wave", _current_wave, "CLEARED! Return to town.")
		wave_cleared.emit(_current_wave)
		$WaveWin.play()
		$"../PlayerBoat".velocity = Vector2.ZERO

		var viewport_tex: Texture2D = get_viewport().get_texture()
		var img: Image = viewport_tex.get_image()
		var screenshot_tex := ImageTexture.create_from_image(img)

		var transition_scene := preload("res://scenes/transitions/WaveTransition.tscn")
		var transition := transition_scene.instantiate()

		get_tree().root.add_child(transition)

		transition.set_screenshot(screenshot_tex)

		$"../PlayerBoat".controls_enabled = false
		$"../PlayerBoat".global_position = Vector2(443, -912)
		$"../PlayerBoat".velocity = Vector2.ZERO
		$"../PlayerBoat".sails_furled = true

		wave_finished.emit()




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


func _update_hud() -> void:
	print("updating the hud")
	if $"../WorldUI":
		$"../WorldUI/MapUI/Wave/".show()
		$"../WorldUI/MapUI/Wave/WaveCount".text = "Wave: %d" % _current_wave
		$"../WorldUI/MapUI/Enemies".show()
		$"../WorldUI/MapUI/Enemies/EnemiesLeft".text = "Enemies: %d" % _enemies_remaining_total
		$"../WorldUI/MapUI/Gold".show()
		$"../WorldUI/MapUI/HealthBar".show()
		$"../WorldUI/MapUI/Drinks".show()


func _play_wave_start_sfx(wave: int, has_boss: bool) -> void:
	# Every 5th wave that actually has a boss: play the boss horn
	if has_boss and wave % 5 == 0 and has_node("BossFogHorn"):
		$BossFogHorn.play()
		return

	# All other waves: normal fog horn
	if has_node("FogHorn"):
		$FogHorn.play()
