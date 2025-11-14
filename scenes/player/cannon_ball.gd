extends Area2D
class_name CannonBall

@export var speed: float = 375.0
@export var damage: int = 20
@export var shooter_group: String = ""

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

func _try_damage(target: Node) -> void:
	if _hit: return  # already hit something

	var n: Node = target
	while n:
		var h := n.get_node_or_null("ShipHealth")
		if h and h.has_method("apply_damage") and h.get_parent().has_method("on_hit"):
			_hit_once()
			h.get_parent().on_hit(h.get_parent().get_parent().get_node("PlayerBoat"))
			_explode_then_free()
			h.apply_damage(damage, self)
			return

		if n.name == "PlayerBoat":
			_hit_once()
			var cur: float = float(n.get("hp"))
			n.set("hp", max(0.0, cur - float(damage)))
			if float(n.get("hp")) == 0.0:
				get_tree().change_scene_to_file("res://scenes/death/YouDied.tscn")
				return
			if n.has_method("play_hit_sound"):
				n.play_hit_sound()
			_explode_then_free()
			return

		n = n.get_parent()

func _hit_once() -> void:
	_hit = true
	speed = 0.0
	# stop any further enter events immediately
	set_deferred("monitoring", false)

func _explode_then_free() -> void:
	if anim: anim.play("explosion")
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_area_entered(a: Area2D) -> void: _try_damage(a)
func _on_body_entered(b: Node2D) -> void: _try_damage(b)
