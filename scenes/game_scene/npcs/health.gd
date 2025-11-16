extends Node
class_name ShipHealth

signal damaged(amount: int, from: Node)
signal died

@export var max_hp: int = 60
var hp: int

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
			print("[ShipHealth] Player died! Play YouDied.tscn")
		else:
			print("[ShipHealth] Enemy ship destroyed:", ship_name)

			# 1) SPAWN TREASURE **DEFERRED** to avoid flushing_queries error
			var drop_pos: Vector2 = ship.global_position
			call_deferred("_spawn_treasure", drop_pos)

			# 2) TRIGGER SHIP DEATH SEQUENCE (defeated sprite + fade)
			if ship.has_method("begin_death"):
				(ship as Node).call("begin_death")
			else:
				# Fallback: if no fancy AI, just free it safely
				ship.call_deferred("queue_free")


func _spawn_treasure(position: Vector2) -> void:
	# This is now called via call_deferred(), outside physics flush
	var treasure := TreasureScene.instantiate()

	# Optional: randomize type + size on spawn
	var types: Array[String] = ["Gold"]
	# var types = ["Gold", "Fish", "Rum", "Ore", "Clothes"]
	var sizes: Array[String] = ["Small", "Medium", "Large"]

	treasure.treasure_type = types[randi() % types.size()]
	treasure.treasure_size = sizes[randi() % sizes.size()]

	treasure.global_position = position

	var root := get_tree().current_scene
	if root:
		root.add_child(treasure)
	else:
		add_child(treasure)  # last-resort fallback
