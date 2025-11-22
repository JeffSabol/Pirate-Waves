extends CharacterBody2D

# --- Upgrade Costs (for town shipyard) ---
@export var speed_upgrade_cost: int = 50
@export var turning_upgrade_cost: int = 50
@export var hull_upgrade_cost: int = 75
@export var guns_upgrade_cost: int = 100

# --- Ship tiering ---
@export var ship_tier: int = 1          # 1 sloop, 2 corsair, 3 brig
@export var max_ship_tier: int = 3      # total number of tiers

# --- Upgrade limits / tracking ---
@export var max_upgrade_level: int = 3  # levels per tier (so 3 tiers => up to 9 total)
@export var speed_upgrade_level: int = 0
@export var turning_upgrade_level: int = 0
@export var hull_upgrade_level: int = 0
@export var guns_upgrade_level: int = 0

# flat increments per level (not exported; we just display the current costs above)
var speed_upgrade_step: int = 25
var turning_upgrade_step: int = 25
var hull_upgrade_step: int = 50
var guns_upgrade_step: int = 50

@export var acceleration := 30.0
@export var deceleration := 10.0
@export var max_speed := 60.0
@export var reverse_speed := 60.0
@export var turn_speed := 1.0

signal hp_changed(hp: int, max_hp: int)

@export var max_hp := 100
@export var hp := 100
@export var guns := 2
# Player Inventory
@export var gold := 1
@export var grog_drink = 0
@export var siren_drink = 0
@export var captain_drink = 0
@export var fish = 1
@export var rum = 1
@export var ore = 1
@export var clothes = 1
# KNOTS
# 1 knot = 10 speed
# Level 1 (small sloop / default): 6 knots
# Level 2 (sloop): 9 knots
# Level 3 (brig): 12 knots
# Level 4 (frigate): 14 knots
@export var knots := 0
@export var morale := 0
@export var left_fire_cooldown := 3
@export var right_fire_cooldown := 3
# Let us toggle control in the editor or from another script
@export var controls_enabled := true
# Current Town Values
@export var in_town_name = ""
@export var in_town_gold = 1
@export var in_town_fish = 1
@export var in_town_rum = 1
@export var in_town_ore = 1
@export var in_town_clothes = 1


@export var can_fire_left := true
@export var can_fire_right := true
@export var combat_lock_seconds: float = 10.0

var sails_furled: bool = true

const FORWARD_BASE := Vector2.UP

var current_speed: float = 0.0
var turn_inertia: float = 0.0  # tiny smoothing for nicer feel
var _last_hp := 0

# --- tiny feel constants (not radical) ---
var idle_drift_speed: float = 5.0        # "move very slowly when not moving"
var idle_turn_factor: float = 0.35       # % of turn_speed you get even at 0 speed
var turn_inertia_gain: float = 12.0      # responsiveness of turn input
var turn_inertia_decay: float = 10.0     # how fast it decays when you stop pressing

# --- Tier collision shapes (assign in inspector) ----------------------------
@export var tier1_shape: Shape2D
@export var tier2_shape: Shape2D
@export var tier3_shape: Shape2D

func enable_controls() -> void:
	controls_enabled = true

func disable_controls() -> void:
	controls_enabled = false

# --- Animation helpers per tier ---------------------------------------------
func _get_furl_anim() -> String:
	match ship_tier:
		1:
			return "furl"
		2:
			return "2_furl"
		3:
			return "3_furl"
		_:
			return "furl"

func _get_raise_anim() -> String:
	match ship_tier:
		1:
			return "raise"
		2:
			return "2_raise"
		3:
			return "3_raise"
		_:
			return "raise"

func _play_sail_idle_frame() -> void:
	var anim_name := _get_furl_anim() if sails_furled else _get_raise_anim()
	var anim := $AnimatedSprite2D
	anim.play(anim_name)
	anim.frame = anim.sprite_frames.get_frame_count(anim_name) - 1
	anim.pause()

# --- Collision shape per tier -----------------------------------------------
func _apply_tier_collision_shape() -> void:
	match ship_tier:
		1:
			if tier1_shape:
				$CollisionShape2D.shape = tier1_shape
		2:
			if tier2_shape:
				$CollisionShape2D.shape = tier2_shape
		3:
			if tier3_shape:
				$CollisionShape2D.shape = tier3_shape

# --- Gun offsets per side (match tier 2 sprite layout) ----------------------
func _apply_gun_offsets() -> void:
	# Only adjust for tier 2+
	if ship_tier < 2:
		return

	var guns_node := $Guns
	for i in range(1, guns_node.get_child_count() + 1):
		var gun := guns_node.get_node_or_null("Gun%d" % i)
		if gun:
			if i % 2 == 1:
				# odd → left
				gun.position.x = -7
			else:
				# even → right
				gun.position.x = 7

func _ready():
	# initial sync
	_last_hp = hp
	emit_signal("hp_changed", hp, max_hp)
	
	sails_furled = true
	current_speed = 0.0
	_play_sail_idle_frame()
	_apply_tier_collision_shape()
	_apply_gun_offsets()

func _physics_process(delta: float) -> void:
	# Detect HP change
	if hp != _last_hp:
		_last_hp = hp
		emit_signal("hp_changed", hp, max_hp)

	# Camera sway (waves / motion feel)
	var cam: Camera2D = $Camera2D
	var sway: float = sin(float(Time.get_ticks_msec()) * 0.0015) * (abs(current_speed) / max_speed) * 0.5
	cam.offset = Vector2(sway, -sway * 0.4)
	
	# If controls are disabled, just slow to a stop and don't accept input
	if not controls_enabled:
		current_speed = lerp(current_speed, 0.0, 0.1)
		velocity = (FORWARD_BASE * current_speed).rotated(rotation)
		move_and_slide()
		return

	# Player input
	var turn_input: float = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		turn_input -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		turn_input += 1.0

	# boat can still rotate when stopped, but turns better with speed
	var speed_ratio: float = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
	var effective_turn: float = turn_speed * (idle_turn_factor + (1.0 - idle_turn_factor) * speed_ratio)

	# a hint of turn inertia for juice (very light)
	turn_inertia = lerp(turn_inertia, turn_input, clamp(turn_inertia_gain * delta, 0.0, 1.0))
	# decay when no input
	if is_zero_approx(turn_input):
		turn_inertia = lerp(turn_inertia, 0.0, clamp(turn_inertia_decay * delta, 0.0, 1.0))

	rotation += effective_turn * turn_inertia * delta
	
	# --- sail state & animations (one-shots) ---
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
		sails_furled = false
		var raise_anim := _get_raise_anim()
		if $AnimatedSprite2D.animation != raise_anim:
			$AnimatedSprite2D.play(raise_anim)
	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_down"):
		sails_furled = true
		var furl_anim := _get_furl_anim()
		if $AnimatedSprite2D.animation != furl_anim:
			$AnimatedSprite2D.play(furl_anim)

	# throttle/brake
	if not sails_furled:
		# normal sailing
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
			current_speed += acceleration * delta
		elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
			current_speed -= deceleration * delta
		else:
			# glide down toward a tiny idle drift forward for “always slightly moving”
			var target_idle := idle_drift_speed
			current_speed = move_toward(current_speed, target_idle, 20.0 * delta)
	else:
		# sails furled → bleed off all motion, no drift
		current_speed = move_toward(current_speed, 0.0, 20.0 * delta)


	# fire controls
	if Input.is_action_just_pressed("fire_left"):
		fire_left_guns()
	if Input.is_action_just_pressed("fire_right"):
		fire_right_guns()

	# clamps and motion
	current_speed = clamp(current_speed, -reverse_speed, max_speed)
	velocity = (FORWARD_BASE * current_speed).rotated(rotation)
	move_and_slide()

	update_guns_visibility()
	update_knots_display()

func update_knots_display() -> void:
	knots = int(round(abs(current_speed) / 10.0))

func update_guns_visibility() -> void:
	var guns_node: Node = $Guns
	var total: int = guns_node.get_child_count()

	for i in range(total):
		var child := guns_node.get_child(i) as CanvasItem
		if child:
			child.visible = (i < guns)

func fire_left_guns() -> void:
	if not can_fire_left:
		return
	can_fire_left = false

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 1:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	# start cooldown timer
	var t: SceneTreeTimer = get_tree().create_timer(left_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_left = true)
	($Camera2D as ShakeCamera).add_trauma(0.3, 0.3)

func fire_right_guns() -> void:
	if not can_fire_right:
		return
	can_fire_right = false

	var guns_node: Node = $Guns
	for i in range(1, guns + 1):
		if i % 2 == 0:
			var gun: Node = guns_node.get_node("Gun%d" % i)
			if gun:
				gun.call("fire")

	# start cooldown timer
	var t: SceneTreeTimer = get_tree().create_timer(right_fire_cooldown)
	t.timeout.connect(func() -> void:
		can_fire_right = true)
	($Camera2D as ShakeCamera).add_trauma(0.3, 0.3)

func play_hit_sound():
	$HitSound.play()
	($Camera2D as ShakeCamera).add_trauma(0.5, 0.3)

func add_loot(treasure_type: String, amount: int):
	match treasure_type:
		"Gold":
			gold += amount
		"Fish":
			fish += amount
		"Rum":
			rum += amount
		"Ore":
			ore += amount
		"Clothes":
			clothes += amount
		_:
			push_warning("Unknown loot type: %s" % treasure_type)
	

# --- Upgrade helpers ---------------------------------------------------------

func _can_afford(cost: int) -> bool:
	return gold >= cost

func _spend_gold(cost: int) -> void:
	gold -= cost
	if gold < 0:
		gold = 0

# per-tier cap (e.g. 3 levels per tier → tier 2 cap = 6)
func _current_tier_cap() -> int:
	return max_upgrade_level * ship_tier

# check if all 4 categories are at the cap for this tier
func _check_tier_progress() -> void:
	if ship_tier >= max_ship_tier:
		return

	var cap := _current_tier_cap()
	if speed_upgrade_level >= cap \
		and turning_upgrade_level >= cap \
		and hull_upgrade_level >= cap \
		and guns_upgrade_level >= cap:
		_advance_ship_tier()

# advance to the next ship tier: keep stats, jump costs, change sails
func _advance_ship_tier() -> void:
	if ship_tier >= max_ship_tier:
		return

	ship_tier += 1
	print("Ship tier advanced to: ", ship_tier)

	# "next calculated 3 values away" → jump each cost by max_upgrade_level steps
	var steps_for_tier_jump := max_upgrade_level
	speed_upgrade_cost += speed_upgrade_step * steps_for_tier_jump
	turning_upgrade_cost += turning_upgrade_step * steps_for_tier_jump
	hull_upgrade_cost += hull_upgrade_step * steps_for_tier_jump
	guns_upgrade_cost += guns_upgrade_step * steps_for_tier_jump

	# update sprite to new tier sails (2_furl/2_raise, 3_furl/3_raise)
	_play_sail_idle_frame()
	_apply_tier_collision_shape()
	_apply_gun_offsets()


# --- Upgrades ----------------------------------------------------------------

func upgrade_speed() -> void:
	if speed_upgrade_level >= _current_tier_cap():
		print("Speed already fully upgraded for this tier")
		$NotEnoughSFX.play()
		return

	if not _can_afford(speed_upgrade_cost):
		print("not enough gold for speed upgrade")
		$NotEnoughSFX.play()
		return

	_spend_gold(speed_upgrade_cost)
	$SawSFX.play()
	# Actual stat buffs (tweak to taste)
	max_speed += 10.0
	acceleration += 5.0
	reverse_speed += 10.0

	speed_upgrade_level += 1
	# Only increase price if we're not at this tier's cap yet
	if speed_upgrade_level < _current_tier_cap():
		speed_upgrade_cost += speed_upgrade_step

	_check_tier_progress()

func upgrade_turning() -> void:
	if turning_upgrade_level >= _current_tier_cap():
		print("Turning already fully upgraded for this tier")
		$NotEnoughSFX.play()
		return

	if not _can_afford(turning_upgrade_cost):
		print("not enough gold for turning upgrade")
		$NotEnoughSFX.play()
		return

	_spend_gold(turning_upgrade_cost)
	$SawSFX.play()

	# Turning buff
	turn_speed += 0.2

	turning_upgrade_level += 1
	if turning_upgrade_level < _current_tier_cap():
		turning_upgrade_cost += turning_upgrade_step

	_check_tier_progress()

func upgrade_hull() -> void:
	if hull_upgrade_level >= _current_tier_cap():
		print("Hull already fully upgraded for this tier")
		$NotEnoughSFX.play()
		return

	if not _can_afford(hull_upgrade_cost):
		print("not enough gold for hull upgrade")
		$NotEnoughSFX.play()
		return

	_spend_gold(hull_upgrade_cost)
	$SawSFX.play()

	# More HP / hull strength
	max_hp += 25
	hp += 25

	hull_upgrade_level += 1
	if hull_upgrade_level < _current_tier_cap():
		hull_upgrade_cost += hull_upgrade_step

	_check_tier_progress()

func upgrade_guns() -> void:
	var guns_node: Node = $Guns
	var max_guns: int = guns_node.get_child_count()

	# Don't charge gold if we're already at max guns
	if guns >= max_guns:
		print("Already at maximum guns")
		$NotEnoughSFX.play()
		return

	if guns_upgrade_level >= _current_tier_cap():
		print("Guns already fully upgraded for this tier")
		$NotEnoughSFX.play()
		return

	if not _can_afford(guns_upgrade_cost):
		print("not enough gold for guns upgrade")
		$NotEnoughSFX.play()
		return

	_spend_gold(guns_upgrade_cost)
	$SawSFX.play()

	guns += 2
	update_guns_visibility()

	guns_upgrade_level += 1
	if guns_upgrade_level < _current_tier_cap():
		guns_upgrade_cost += guns_upgrade_step

	_check_tier_progress()
