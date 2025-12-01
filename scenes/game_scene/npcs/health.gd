extends Node
class_name BossHealth

signal damaged(amount: int, from: Node)
signal died

@export var max_hp: int = 500
@export var hp: int

# Make sure we only die once
var _is_dead: bool = false

const TreasureScene := preload("res://scenes/game_scene/npcs/treasure.tscn")

@onready var _ship: Node2D = get_parent() as Node2D


func _ready() -> void:
	hp = max_hp

	# Debug info
	if _ship:
		if _ship is BossAI:
			print("[BossHealth]", _ship.name, "READY as BOSS. max_hp =", max_hp)
		elif _ship is ShipAI:
			print("[BossHealth]", _ship.name, "READY as normal enemy ship. max_hp =", max_hp)
		else:
			print("[BossHealth]", _ship.name, "READY but parent is not ShipAI/BossAI")
	else:
		print("[BossHealth] READY but no parent ship found")


func apply_damage(amount: int, from: Node) -> void:
	if _is_dead:
		return

	hp = max(hp - amount, 0)
	damaged.emit(amount, from)

	# Hit sound if present
	var hit_sound := get_node_or_null("../HitSound")
	if hit_sound:
		hit_sound.play()

	# Let the parent AI (BossAI / ShipAI) know HP changed if it cares
	if _ship and _ship.has_method("update_boss_health"):
		print("[BossHealth]", _ship.name, "HP changed:", hp, "/", max_hp, "-> calling update_boss_health")
		_ship.update_boss_health(hp, max_hp)

	if hp == 0:
		_is_dead = true
		died.emit()

		if _ship == null:
			return

		if _ship.name == "PlayerBoat":
			print("[BossHealth] Player died! (this shouldn't normally happen here)")
		else:
			print("[BossHealth] Enemy ship destroyed:", _ship)

			var death_pos: Vector2 = _ship.global_position
			call_deferred("_handle_enemy_death", _ship, death_pos)


func _handle_enemy_death(ship: Node2D, death_pos: Vector2) -> void:
	# Spawn treasure
	_spawn_treasure(death_pos)

	# Boss / ship AI handles death fade + despawn
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

	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	root.call_deferred("add_child", treasure)
