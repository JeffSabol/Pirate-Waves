extends ColorRect

func _on_mouse_entered():
	print("mouse in spyglass")
	$"../SpyglassGlow".show()

func _on_mouse_exited():
	$"../SpyglassGlow".hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("load spyglass card!")
