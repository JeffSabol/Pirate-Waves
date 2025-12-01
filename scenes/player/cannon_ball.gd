extends Area2D
class_name CannonBall

@export var speed: float = 300.0
@export var damage: int = 20
@export var shooter_group: String = ""   # set to "player" for player-fired balls

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _hit := false

func _ready() -> void:
	if notifier:
		notifier.screen_exited.connect(queue_free)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if _hit: return
	position += Vector2.RIGHT.rotated(global_rotation) * speed * delta

# --------------------------------------------------------------------
# Damage helpers
# --------------------------------------------------------------------
func _get_player_boat() -> Node:
	# Prefer group lookup if you have the player in a group.
	var p := get_tree().get_first_node_in_group("player")
	if p:
		return p

	# Fallback: try to find a node named PlayerBoat in the current scene
	var scene := get_tree().current_scene
	if scene:
		var by_name := scene.get_node_or_null("PlayerBoat")
		if by_name:
			return by_name
		# last-resort search
		var found := scene.find_child("PlayerBoat", true, false)
		if found:
			return found

	return null

func _compute_effective_damage() -> int:
	var eff := damage

	# Only boost PLAYER-fired cannonballs.
	if shooter_group == "player":
		var player := _get_player_boat()
		if player:
			var mult := 1.0
			# Support either property or method (your PlayerBoat has both)
			if player.has_method("get_cannon_damage_multiplier"):
				mult = float(player.get_cannon_damage_multiplier())
			elif player.has_variable("cannon_damage_multiplier"):
				mult = float(player.cannon_damage_multiplier)

			eff = int(round(float(damage) * mult))

	return eff

# --------------------------------------------------------------------
# Collision / apply damage
# --------------------------------------------------------------------
func _try_damage(target: Node) -> void:
	if _hit:
		return  # already hit something

	var n: Node = target
	while n:
		# -------- ENEMY SHIPS / BOSS (treat as "enemies") --------
		var h := n.get_node_or_null("ShipHealth")
		if h and h.has_method("apply_damage") and h.get_parent().has_method("on_hit"):
			# FRIENDLY FIRE CHECK:
			# Only player-fired cannonballs are allowed to damage ships.
			if shooter_group != "player":
				return

			_hit_once()

			var eff_damage := _compute_effective_damage()

			# Notify the AI it was hit by the player
			h.get_parent().on_hit(h.get_parent().get_parent().get_node("PlayerBoat"))
			_explode_then_free()
			h.apply_damage(eff_damage, self)
			return

		var h2 := n.get_node_or_null("BossHealth")
		if h2 and h2.has_method("apply_damage") and h2.get_parent().has_method("on_hit"):
			# FRIENDLY FIRE CHECK:
			if shooter_group != "player":
				return

			_hit_once()

			var eff_damage := _compute_effective_damage()

			h2.get_parent().on_hit(h2.get_parent().get_parent().get_node("PlayerBoat"))
			_explode_then_free()
			h2.apply_damage(eff_damage, self)
			return

		# -------- PLAYER DAMAGE --------
		if n.name == "PlayerBoat":
			_hit_once()
			# Enemy balls should hit the player regardless of shooter_group.
			var cur: float = float(n.get("hp"))
			n.set("hp", max(0.0, cur - float(damage)))
			if float(n.get("hp")) == 0.0:
				call_deferred("_go_to_death_screen")
				return
			if n.has_method("play_hit_sound"):
				n.play_hit_sound()
			_explode_then_free()
			return

		n = n.get_parent()


func _hit_once() -> void:
	_hit = true
	speed = 0.0
	set_deferred("monitoring", false)

func _explode_then_free() -> void:
	if anim: anim.play("explosion")
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_area_entered(a: Area2D) -> void: _try_damage(a)
func _on_body_entered(b: Node2D) -> void: _try_damage(b)

func _go_to_death_screen() -> void:
	get_tree().change_scene_to_file("res://scenes/death/YouDied.tscn")
