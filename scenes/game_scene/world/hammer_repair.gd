extends TextureButton

@onready var player: Node2D = $"../../../../PlayerBoat"

# Greyed-out texture when hammer can't be used
const HAMMER_GREY := preload("res://assets/ui/worldui/items_hud/hammer_grey.png")

var _base_texture: Texture2D        # original hammer texture (colored)
var _last_can_use: bool = false     # track state changes for fade


func _ready() -> void:
	# Remember whatever texture is already assigned as the "normal" colored hammer
	_base_texture = texture_normal
	if _base_texture == null:
		push_warning("Hammer button: texture_normal is null in the inspector. Assign a base hammer texture.")

	tooltip_text = "Hammers: 0\nYou need a hammer to repair your ship."

	# Force initial visual state update
	_update_visual_state()


func _process(delta: float) -> void:
	if !is_instance_valid(player):
		return

	_update_visual_state()


func _update_visual_state() -> void:
	if !is_instance_valid(player):
		return

	if player.hammer_count <= 0:
		visible = false
		disabled = true
		texture_normal = HAMMER_GREY
		tooltip_text = "Hammers: 0\nYou need to buy a hammer."
		return
	else:
		visible = true  # player owns at least one hammer

	var can_use: bool = (player.hp < player.max_hp)

	if can_use != _last_can_use:
		_last_can_use = can_use

		if can_use:
			texture_normal = _base_texture
			disabled = false
		else:
			texture_normal = HAMMER_GREY
			disabled = true

		_play_fade(can_use)

	_update_tooltip(can_use)


func _play_fade(can_use: bool) -> void:
	var tween := create_tween()

	if can_use:
		# Fade into full opacity
		modulate = Color(1, 1, 1, 0.6)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.18)
	else:
		# Fade slightly dim
		modulate = Color(1, 1, 1, 1.0)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0.7), 0.18)


func _update_tooltip(can_use: bool) -> void:
	if !is_instance_valid(player):
		return

	var count: int = player.hammer_count

	if count <= 0:
		tooltip_text = "Hammers: 0\nYou need to buy a hammer."
		return

	if can_use:
		tooltip_text = "Hammers: %d\nClick to repair 10 HP." % count
	else:
		if player.hp >= player.max_hp:
			tooltip_text = "Hammers: %d\nYour ship is already at full health." % count
		else:
			tooltip_text = "Hammers: %d\nYou can’t repair right now." % count


func _on_pressed() -> void:
	if !is_instance_valid(player):
		return

	var max_hp: int = player.max_hp
	var hp: int = player.hp

	if player.hammer_count <= 0:
		$ErrorSound.play()
		return

	if hp >= max_hp:
		$ErrorSound.play()
		return

	player.hammer_count -= 1
	player.hp = min(hp + 10, max_hp)

	$HammerSound.play()

	print("Repaired with hammer! New HP =", player.hp,
		  "   Hammers left =", player.hammer_count)
