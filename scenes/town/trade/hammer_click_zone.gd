extends ColorRect

func _on_mouse_entered():
	$HammerGlow.show()

func _on_mouse_exited():
	$HammerGlow.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("load hammer card")
