# cannon_ball.gd
class_name CannonBall
extends Node2D

@export var speed: float = 375.0
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	if notifier:
		notifier.screen_exited.connect(queue_free)
	# Fail-safe in case it never leaves screen:
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(global_rotation) * speed * delta
