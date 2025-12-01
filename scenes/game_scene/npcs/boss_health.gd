extends Node

signal damaged(amount: int, from: Node)
signal died

@export var max_hp: int = 500
@export var hp: int

# Make sure we only die once
var _is_dead: bool = false

const TreasureScene := preload("res://scenes/game_scene/npcs/treasure.tscn")

@onready var _ship: Node2D = get_parent() as Node2D
# NOTE: don't lock this to ShipAI; parent might be BossAI
# we'll just treat _ship as a generic node and check methods as needed


func _ready() -> void:
	hp = max_hp

	# Debug info so we can see whether this is a boss or normal ship
	var ship_ai := _ship as ShipAI
	if ship_ai and ship_ai.enable_ghost_special:
		print("[ShipHealth]", _ship.name, "READY as BOSS. Ghost special ENABLED. max_hp =", max_hp)
	elif ship_ai:
		print("[ShipHealth]", _ship.name, "READY as normal enemy ship. max_hp =", max_hp)
	else:
		print("[ShipHealth]", _ship.name, "READY but no ShipAI on parent (probably player or other)")


func apply_damage(amount: int, from: Node) -> void:
	# ---- GUARD: if we're already dead / in death sequence, ignore further hits ----
	if _is_dead:
		return

	hp = max(hp - amount, 0)
	damaged.emit(amount, from)

	# Play hit sound if present (../HitSound)
	var hit_sound := get_node_or_null("../HitSound")
	if hit_sound:
		hit_sound.play()

	# Let the parent AI (ShipAI or BossAI) know HP changed, if it cares
	if _ship and _ship.has_method("update_boss_health"):
		print("[ShipHealth]", _ship.name, "HP changed:", hp, "/", max_hp, "-> calling update_boss_health")
		_ship.update_boss_health(hp, max_hp)

	# ---- Death handling ----
	if hp == 0:
		_is_dead = true
		died.emit()

		if _ship == null:
			return

		if _ship.name == "PlayerBoat":
			print("[ShipHealth] Player died! Play YouDied.tscn or handle game over.")
			# Player death handling is done elsewhere (death screen, etc.)
		else:
			print("[ShipHealth] Enemy ship destroyed:", _ship)

			# cache position now (in case ship moves/gets freed)
			var death_pos: Vector2 = _ship.global_position

			# Do the rest deferred so we don't mess with physics flushing
			call_deferred("_handle_enemy_death", _ship, death_pos)


func _handle_enemy_death(ship: Node2D, death_pos: Vector2) -> void:
	# Spawn treasure
	_spawn_treasure(death_pos)

	# Works for both ShipAI and BossAI
	if ship and ship.has_method("begin_death"):
		ship.begin_death()
	else:
		ship.queue_free()


func _spawn_treasure(position: Vector2) -> void:
	var treasure := TreasureScene.instantiate()

	var types = ["Gold"]
	var sizes = ["Large"]

	treasure.treasure_type = types[randi() % types.size()]
	treasure.treasure_size = sizes[randi() % sizes.size()]

	treasure.global_position = position

	# Use deferred add_child to avoid physics "flushing queries" issues
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	root.call_deferred("add_child", treasure)
