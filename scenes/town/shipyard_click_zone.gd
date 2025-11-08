extends ColorRect

func _on_mouse_entered():
	$ShipyardGlow.show()

func _on_mouse_exited():
	$ShipyardGlow.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		$"../../../../GameUI".show_shipyard_ui()
