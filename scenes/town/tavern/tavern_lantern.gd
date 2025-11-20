extends PointLight2D

@export var min_energy := 0.4
@export var max_energy := 0.95
@export var flicker_speed := 1.0

func _ready():
	flicker()

func flicker():
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Energy flicker (brightness)
	tween.tween_property(self, "energy", randf_range(min_energy, max_energy), flicker_speed)
	tween.tween_property(self, "energy", randf_range(min_energy, max_energy), flicker_speed)

	# Optional: subtle scale wobble for extra realism
	tween.parallel().tween_property(self, "texture_scale", randf_range(0.95, 1.05), flicker_speed * 0.8)
