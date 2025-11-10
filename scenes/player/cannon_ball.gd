extends Area2D
class_name CannonBall

@export var speed: float = 375.0
@export var damage: int = 20
@export var shooter_group: String = ""  # e.g. "player", "pirate", "merchant" to avoid friendly fire if you want

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	if notifier:
		notifier.screen_exited.connect(queue_free)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(global_rotation) * speed * delta

func _try_damage(target: Node) -> void:
	var n: Node = target
	while n:
		# ---- Ship enemy damage ----
		var h := n.get_node_or_null("ShipHealth")
		if h and h.has_method("apply_damage") and h.get_parent().has_method("on_hit"):
			h.get_parent().on_hit(h.get_parent().get_parent().get_node("PlayerBoat"))
			h.apply_damage(damage, self)
			queue_free()
			return

		# ---- PlayerBoat damage ----
		if n.name == "PlayerBoat":
			var cur := n.get("hp") as float
			n.set("hp", max(0.0, cur - float(damage)))
			if (n.get("hp") == 0.0):
				print("GO TO YOU DIED SCENE")
			return

		n = n.get_parent()


func _on_area_entered(a: Area2D) -> void:
	_try_damage(a)

func _on_body_entered(b: Node2D) -> void:
	_try_damage(b)
