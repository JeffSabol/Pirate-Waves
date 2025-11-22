extends Node2D

@export_enum("Pirate", "Poor", "Middle", "Good", "Wealthy")
var town_type: String = "Poor"

@export var town_name: String = ""
@export var merchant_gold: int
@export var merchant_fish: int
@export var merchant_rum: int
@export var merchant_ore: int
@export var merchant_clothes: int

var _player_in_zone: Node = null
var _town_ui_open: bool = false

func _ready() -> void:
	set_sprite_by_type()

	# Hook wave-finished so we can retry town entry if player stayed in zone
	var wm := $"../../WaveManager"
	if wm and wm.has_signal("wave_finished"):
		wm.wave_finished.connect(_on_wave_finished)

func set_sprite_by_type() -> void:
	match town_type:
		"Poor":
			$Building.play("poor")
		"Middle":
			$Building.play("middle")
		"Good":
			$Building.play("good")
		"Wealthy":
			$Building.play("wealthy")
		_:
			$Building.play("poor")
	$Building.stop()

func _on_enter_zone_body_entered(body: Node) -> void:
	if body.name != "PlayerBoat":
		return

	_player_in_zone = body
	_try_enter_town(body)

func _on_enter_zone_body_exited(body: Node) -> void:
	if body.name != "PlayerBoat":
		return

	# Leaving town zone => start next wave (as long as Shipyard isn't open)
	if get_tree().root.find_child("Shipyard", true, false) == null:
		var wm := $"../../WaveManager"
		if wm:
			wm.request_start_wave_from_town()

	_player_in_zone = null
	_town_ui_open = false  # allow re-entry later

func _on_wave_finished() -> void:
	# Wave ended while player was still parked in zone
	if _player_in_zone:
		_try_enter_town(_player_in_zone)

func _try_enter_town(body: Node) -> void:
	if _town_ui_open:
		return
	if body == null or body.name != "PlayerBoat":
		return

	var wm := $"../../WaveManager"
	if wm == null:
		return

	var shipyard_open := get_tree().root.find_child("Shipyard", true, false) != null
	if wm.wave_active or shipyard_open:
		return

	# Enter town
	_town_ui_open = true
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
