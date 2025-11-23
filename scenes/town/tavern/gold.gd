extends Control

@onready var player: Node2D = get_node("../../../../PlayerBoat")

func _process(_delta):
	$Gold.text = str(player.gold)
