extends TextureRect

var dragging := false
var drag_offset := Vector2.ZERO

const LEVELS_PER_TIER := 3

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

# 🔹 These will error loudly if the path is wrong (which is what we want while wiring it up)
@onready var hp_label: Label = $"../RepairCostPanel/Label/HpCountLabel"
@onready var gold_repair_label: Label = $"../RepairCostPanel/Label/GoldRepairCountLabel"


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


func _physics_process(_delta):
	var player = $"../../../../PlayerBoat"

	var missing_hp: int = max(player.max_hp - player.hp, 0)

	if missing_hp <= 0:
		$RepairClickZone.tooltip_text = "Ship fully repaired"
	else:
		# 1 gold per 1 HP, but tooltip shows how much you can actually repair right now
		var hp_affordable: int = min(player.gold, missing_hp)
		$RepairClickZone.tooltip_text = "Repair Ship for %d" % hp_affordable

	$GoldBalance.text = str(player.gold)

	# -----------------------------
	# REPAIR COST PANEL LABELS
	# -----------------------------
	# HP: always show current / max
	hp_label.text = "%d/%d" % [player.hp, player.max_hp]

	# Gold repair:
	# - N/A at full HP
	# - otherwise full cost to fully repair (missing_hp)
	if missing_hp <= 0:
		gold_repair_label.text = "NA"
	else:
		gold_repair_label.text = str(missing_hp)

	# -----------------------------
	# PRICE LABELS
	# -----------------------------
	var tier_cap: int = player.max_upgrade_level * player.ship_tier

	if player.speed_upgrade_level >= tier_cap:
		$SpeedPriceLabel.text = "MAX"
	else:
		$SpeedPriceLabel.text = str(player.speed_upgrade_cost)

	if player.turning_upgrade_level >= tier_cap:
		$TurningPriceLabel.text = "MAX"
	else:
		$TurningPriceLabel.text = str(player.turning_upgrade_cost)

	if player.hull_upgrade_level >= tier_cap:
		$HullPriceLabel.text = "MAX"
	else:
		$HullPriceLabel.text = str(player.hull_upgrade_cost)

	if player.guns_upgrade_level >= tier_cap:
		$GunsPriceLabel.text = "MAX"
	else:
		$GunsPriceLabel.text = str(player.guns_upgrade_cost)

	# -----------------------------
	# UPGRADE INDICATOR TEXTURES
	# -----------------------------
	var tier: int = player.ship_tier

	# Convert the GLOBAL upgrade level (0..9) into "level in current tier" (0..3)
	# This is what makes tier 2 start as empty, using empty_upgrade_indicator.
	var speed_level_in_tier   : int = _compute_level_in_tier(player.speed_upgrade_level,   tier)
	var turning_level_in_tier : int = _compute_level_in_tier(player.turning_upgrade_level, tier)
	var hull_level_in_tier    : int = _compute_level_in_tier(player.hull_upgrade_level,    tier)
	var guns_level_in_tier    : int = _compute_level_in_tier(player.guns_upgrade_level,    tier)

	var speed_indicator   := $SpeedIndicator   if has_node("SpeedIndicator")   else null
	var turning_indicator := $TurningIndicator if has_node("TurningIndicator") else null
	var hull_indicator    := $HullIndicator    if has_node("HullIndicator")    else null
	var guns_indicator    := $GunsIndicator    if has_node("GunsIndicator")    else null

	if speed_indicator:
		speed_indicator.texture = _get_indicator_texture(tier, speed_level_in_tier)
	if turning_indicator:
		turning_indicator.texture = _get_indicator_texture(tier, turning_level_in_tier)
	if hull_indicator:
		hull_indicator.texture = _get_indicator_texture(tier, hull_level_in_tier)
	if guns_indicator:
		guns_indicator.texture = _get_indicator_texture(tier, guns_level_in_tier)


func _compute_level_in_tier(global_level: int, tier: int) -> int:
	var min_level_for_tier = (tier - 1) * LEVELS_PER_TIER
	var relative = global_level - min_level_for_tier
	return clamp(relative, 0, LEVELS_PER_TIER)


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
		$RepairClickZone/AudioStreamPlayer.play()
