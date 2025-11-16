extends Node
class_name ShipHealth

signal damaged(amount: int, from: Node)
signal died

@export var max_hp: int = 60
var hp: int

# Make sure we only die once
var _is_dead: bool = false

const TreasureScene := preload("res://scenes/game_scene/npcs/treasure.tscn")

func _ready() -> void:
	hp = max_hp


func apply_damage(amount: int, from: Node) -> void:
	# ---- GUARD: if we're already dead / in death sequence, ignore further hits ----
	if _is_dead:
		return

	hp = max(hp - amount, 0)
	damaged.emit(amount, from)
	$"../HitSound".play()

	if hp == 0:
		_is_dead = true  # <-- critical line

		died.emit()

		var ship := get_parent() as Node2D
		if ship == null:
			return

		if ship.name == "PlayerBoat":
			print("[ShipHealth] Player died! Play YouDied.tscn or handle game over.")
		else:
			print("[ShipHealth] Enemy ship destroyed:", ship)

			# cache position now (in case ship moves/gets freed)
			var death_pos: Vector2 = ship.global_position

			# Do the rest deferred so we don't mess with physics flushing
			call_deferred("_handle_enemy_death", ship, death_pos)


func _handle_enemy_death(ship: Node2D, death_pos: Vector2) -> void:
	# Spawn treasure
	_spawn_treasure(death_pos)

	# If this ship uses ShipAI, let it do the fancy fade-out
	var ai := ship as ShipAI
	if ai:
		ai.begin_death()
	else:
		ship.queue_free()


func _spawn_treasure(position: Vector2) -> void:
	var treasure := TreasureScene.instantiate()

	# Optional: randomize type + size on spawn, or keep your Gold-only setup
	var types = ["Gold"]
	var sizes = ["Small", "Medium", "Large"]

	treasure.treasure_type = types[randi() % types.size()]
	treasure.treasure_size = sizes[randi() % sizes.size()]

	treasure.global_position = position

	# Use deferred add_child to avoid physics "flushing queries" issues
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	root.call_deferred("add_child", treasure)
