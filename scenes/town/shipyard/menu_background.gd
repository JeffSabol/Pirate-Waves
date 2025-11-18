extends TextureRect

var dragging := false
var drag_offset := Vector2.ZERO

# --- UPGRADE INDICATOR TEXTURES ---

@export var empty_upgrade_indicator: Texture2D

@export var tier1_upgrade_indicator1: Texture2D
@export var tier1_upgrade_indicator2: Texture2D
@export var tier1_upgrade_indicator3: Texture2D

@export var tier2_upgrade_indicator1: Texture2D
@export var tier2_upgrade_indicator2: Texture2D
@export var tier2_upgrade_indicator3: Texture2D

@export var tier3_upgrade_indicator1: Texture2D
@export var tier3_upgrade_indicator2: Texture2D
@export var tier3_upgrade_indicator3: Texture2D


func _ready():
	$GoldBalance.text = str($"../../../../PlayerBoat".gold)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			# Store how far inside the panel we clicked (in GLOBAL space)
			drag_offset = get_global_mouse_position() - global_position
			accept_event()
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		# Keep the same offset while we drag
		global_position = get_global_mouse_position() - drag_offset
		accept_event()


func _physics_process(delta):
	var player = $"../../../../PlayerBoat"

	$GoldBalance.text = str(player.gold)

	# SPEED
	if player.speed_upgrade_level >= player.max_upgrade_level:
		$SpeedPriceLabel.text = "MAX"
	else:
		$SpeedPriceLabel.text = str(player.speed_upgrade_cost)

	# TURNING
	if player.turning_upgrade_level >= player.max_upgrade_level:
		$TurningPriceLabel.text = "MAX"
	else:
		$TurningPriceLabel.text = str(player.turning_upgrade_cost)

	# HULL
	if player.hull_upgrade_level >= player.max_upgrade_level:
		$HullPriceLabel.text = "MAX"
	else:
		$HullPriceLabel.text = str(player.hull_upgrade_cost)

	# GUNS
	if player.guns_upgrade_level >= player.max_upgrade_level:
		$GunsPriceLabel.text = "MAX"
	else:
		$GunsPriceLabel.text = str(player.guns_upgrade_cost)

	# -----------------------------
	# UPGRADE INDICATOR TEXTURES
	# -----------------------------
	var tier: int = player.ship_tier

	# Clamp to 0..3 since you have 0–3 circles filled
	var speed_level   : int = clamp(player.speed_upgrade_level,   0, 3)
	var turning_level : int = clamp(player.turning_upgrade_level, 0, 3)
	var hull_level    : int = clamp(player.hull_upgrade_level,    0, 3)
	var guns_level    : int = clamp(player.guns_upgrade_level,    0, 3)

	var speed_indicator   := $SpeedIndicator   if has_node("SpeedIndicator")   else null
	var turning_indicator := $TurningIndicator if has_node("TurningIndicator") else null
	var hull_indicator    := $HullIndicator    if has_node("HullIndicator")    else null
	var guns_indicator    := $GunsIndicator    if has_node("GunsIndicator")    else null

	if speed_indicator:
		speed_indicator.texture = _get_indicator_texture(tier, speed_level)
	if turning_indicator:
		turning_indicator.texture = _get_indicator_texture(tier, turning_level)
	if hull_indicator:
		hull_indicator.texture = _get_indicator_texture(tier, hull_level)
	if guns_indicator:
		guns_indicator.texture = _get_indicator_texture(tier, guns_level)


func _get_indicator_texture(tier: int, level_in_tier: int) -> Texture2D:
	# 0 = empty, 1–3 = filled circles
	if level_in_tier <= 0:
		return empty_upgrade_indicator
	if level_in_tier > 3:
		level_in_tier = 3

	match tier:
		1:
			match level_in_tier:
				1:
					return tier1_upgrade_indicator1
				2:
					return tier1_upgrade_indicator2
				3:
					return tier1_upgrade_indicator3
		2:
			match level_in_tier:
				1:
					return tier2_upgrade_indicator1
				2:
					return tier2_upgrade_indicator2
				3:
					return tier2_upgrade_indicator3
		3:
			match level_in_tier:
				1:
					return tier3_upgrade_indicator1
				2:
					return tier3_upgrade_indicator2
				3:
					return tier3_upgrade_indicator3

	# Fallback
	return empty_upgrade_indicator


func _on_speed_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_speed()


func _on_turning_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_turning()


func _on_hull_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_hull()


func _on_guns_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_guns()


func _on_exit_click_zone_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		$"./../../".queue_free()


func _on_repair_click_zone_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var player = $"../../../../PlayerBoat"

		var missing_hp = player.max_hp - player.hp
		if missing_hp <= 0:
			print("Ship already fully repaired.")
			$"../../../../PlayerBoat/NotEnoughSFX".play()
			return

		var repair_cost = missing_hp  # 1 gold per 1 HP

		# If not enough gold, repair partially
		var amount_affordable = min(player.gold, missing_hp)

		if amount_affordable <= 0:
			print("Not enough gold to repair.")
			$"../../../../PlayerBoat/NotEnoughSFX".play()
			return

		# Apply repair
		player.hp += amount_affordable
		player.gold -= amount_affordable

		print("Repaired ", amount_affordable, " HP for ", amount_affordable, " gold.")
		$"../../../../PlayerBoat/SawSFX".play()
