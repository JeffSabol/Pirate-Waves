extends ColorRect

func _on_mouse_entered():
	$"../HammerGlow".show()

func _on_mouse_exited():
	$"../HammerGlow".hide()
