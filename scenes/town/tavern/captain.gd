extends ColorRect

func _on_mouse_entered():
	$"../CaptainGlow".show()

func _on_mouse_exited():
	$"../CaptainGlow".hide()
