extends ColorRect

func _ready() -> void:
	# Fade IN when entering the world for the first time
	fade_in()


func fade_in(duration: float = 1.2) -> void:
	# Start fully black
	color = Color(0, 0, 0, 1.0)
	show()

	var tween := create_tween()
	tween.tween_property(self, "color", Color(0,0,0,0), duration)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# After fade-in: hide (so UI responds to clicks)
	tween.finished.connect(func():
		hide()
	)


func fade_out(duration: float = 0.8, after_callback: Callable = Callable()) -> void:
	# Start fully transparent black
	color = Color(0, 0, 0, 0.0)
	show()

	var tween := create_tween()
	tween.tween_property(self, "color:a", 1.0, duration)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		if after_callback.is_valid():
			after_callback.call()
	)
