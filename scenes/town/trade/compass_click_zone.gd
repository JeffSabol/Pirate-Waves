extends ColorRect

func _on_mouse_entered():
	$"../CompassGlow".show()

func _on_mouse_exited():
	$"../CompassGlow".hide()
