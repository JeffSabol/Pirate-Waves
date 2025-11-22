extends Control

@onready var player: Node2D = get_node("../../../PlayerBoat")

func _process(_delta: float) -> void:
	_sync_drink_emblems()

func _sync_drink_emblems() -> void:
	# Only toggle if node exists (prevents null errors).
	if $VBoxContainer/Siren and player.siren_drink > 0:
		$VBoxContainer/Siren.show()
	if $VBoxContainer/Grog and player.grog_drink > 0:
		$VBoxContainer/Grog.show()
	if $VBoxContainer/Captain and player.captain_drink > 0:
		$VBoxContainer/Captain.show()
