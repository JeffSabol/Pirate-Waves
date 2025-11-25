extends ColorRect

func _on_mouse_entered():
	$Leave1Glow.show()

func _on_mouse_exited():
	print("hide glow")
	$Leave1Glow.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		$"../".queue_free()
