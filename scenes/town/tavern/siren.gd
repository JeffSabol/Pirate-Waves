extends ColorRect

func _on_mouse_entered():
	$"../SirenGlow".show()

func _on_mouse_exited():
	$"../SirenGlow".hide()
