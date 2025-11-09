extends Node
class_name ShipHealth

signal damaged(amount: int, from: Node)
signal died

@export var max_hp: int = 60
var hp: int

func _ready() -> void:
	hp = max_hp

func apply_damage(amount: int, from: Node) -> void:
	hp = max(hp - amount, 0)
	damaged.emit(amount, from)
	$"../HitSound".play()
	if hp == 0:
		print("from " + str(from))
		died.emit()
		print(get_parent().name)
		if (get_parent().name=="PlayerBoat"):
			# Cannon ball send from player will delete the enemy
			print("player player died! play the YouDied.tscn")
		elif (get_parent().name.contains("Area2D")):
			print("Remove enemy ship!")
			get_parent().queue_free()
