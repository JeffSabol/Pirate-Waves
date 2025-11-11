extends Node
class_name ShipHealth

signal damaged(amount: int, from: Node)
signal died

@export var max_hp: int = 60
var hp: int

# Preload the treasure scene once
const TreasureScene := preload("res://scenes/game_scene/npcs/treasure.tscn")

func _ready() -> void:
	hp = max_hp

func apply_damage(amount: int, from: Node) -> void:
	hp = max(hp - amount, 0)
	damaged.emit(amount, from)
	$"../HitSound".play()

	if hp == 0:
		died.emit()

		var ship := get_parent()
		var ship_name := ship.name

		if ship_name == "PlayerBoat":
			print("player died! Play YouDied.tscn")
		else:
			print("Enemy ship destroyed: " + ship_name)

			# ---- SPAWN TREASURE HERE ----
			_spawn_treasure(ship.global_position)

			ship.queue_free()


func _spawn_treasure(position: Vector2) -> void:
	var treasure := TreasureScene.instantiate()

	# Optional: randomize type + size on spawn
	var types = ["Gold", "Fish", "Rum", "Ore", "Clothes"]
	var sizes = ["Small", "Medium", "Large"]

	treasure.treasure_type = types[randi() % types.size()]
	treasure.treasure_size = sizes[randi() % sizes.size()]

	treasure.global_position = position
	get_tree().current_scene.add_child(treasure)
