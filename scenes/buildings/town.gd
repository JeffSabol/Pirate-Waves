extends Node2D

@export_enum("Pirate", "Poor", "Middle", "Good", "Wealthy")
var town_type: String = "Poor"
@export var town_name: String = ""
@export var merchant_gold: int
@export var merchant_fish: int
@export var merchant_rum: int
@export var merchant_ore: int
@export var merchant_clothes: int

func _ready():
	set_sprite_by_type()

func set_sprite_by_type():
	match town_type:
		# I never found an asset that looks like a pirate hangout yet.
		#"Pirate":
			#$Building.play("pirate")
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
		# Don't allow town scene if they were recently shot
		print(str(body.has_recently_been_shot()))
		if !body.has_recently_been_shot():
			$Building.play()
			$"../../GameUI".hide_world_ui()
			$"../../GameUI".show_town_ui()
			$"../../PlayerBoat/AudioStreamPlayer2D".stop()
			body.in_town_name = town_name 
			body.in_town_gold = merchant_gold
			body.in_town_fish = merchant_fish
			body.in_town_rum = merchant_rum
			body.in_town_ore = merchant_ore
			body.in_town_clothes = merchant_clothes

func _on_enter_zone_body_exited(body):
	if body.name == "PlayerBoat":
		var wm := $"../../WaveManager"
		if wm:
			wm.request_start_wave_from_town()
