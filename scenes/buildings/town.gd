extends Node2D

@export_enum("Pirate", "Poor", "Middle", "Good", "Wealthy")
var town_type: String = "Poor"

func _ready():
	set_sprite_by_type()

func set_sprite_by_type():
	match town_type:
		"Pirate":
			$Building.play("pirate")
		"Poor":
			$Building.play("poor")
		"Middle":
			$Building.play("middle")
		"Good":
			$Building.play("good")
		"Wealthy":
			$Building.play("wealthy")
	$Building.stop()

func _on_enter_zone_body_entered(body):
	if body.name == "PlayerBoat":
		$Building.play()
		await get_tree().create_timer(0.5).timeout
		$"../../GameUI".hide_world_ui()
		$"../../GameUI".show_town_ui()
		$"../../PlayerBoat/AudioStreamPlayer2D".stop()
		
