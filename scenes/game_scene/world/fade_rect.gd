extends ColorRect

func _ready():
	fade_in()

func fade_in():
	# Fully opaque to start
	self.color = Color(0, 0, 0, 1.0)

	var tween := create_tween()
	tween.tween_property(self, "color", Color(0, 0, 0, 0.0), 1.5) # 1.5 sec fade
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): queue_free())
 
