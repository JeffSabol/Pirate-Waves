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
		var h := n.get_node_or_null("ShipHealth")
		if h and h.has_method("apply_damage"):
			h.get_parent().on_hit(h.get_parent().get_parent().get_node("PlayerBoat"))
			h.apply_damage(damage, self)
			queue_free()
			return

		if n.name == "PlayerBoat":
			if n.has_method("set") and (n.has_property("HP") or true):
				if "HP" in n:
					n.HP = max(0.0, float(n.HP) - float(damage))
					queue_free()
					return
				elif n.has_property("HP"):
					var cur := float(n.get("HP"))
					n.set("HP", max(0.0, cur - float(damage)))
					print("GO TO YOU DIED SCENE")
					return

		n = n.get_parent()


func _on_area_entered(a: Area2D) -> void:
	_try_damage(a)

func _on_body_entered(b: Node2D) -> void:
	_try_damage(b)
