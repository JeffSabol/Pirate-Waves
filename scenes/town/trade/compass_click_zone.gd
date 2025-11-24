extends ColorRect

func _on_mouse_entered():
	$CompassGlow.show()

func _on_mouse_exited():
	$CompassGlow.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("load compass card!")
