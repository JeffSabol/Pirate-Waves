extends ColorRect

func _on_mouse_entered():
	$"../GrogGlow".show()

func _on_mouse_exited():
	$"../GrogGlow".hide()
