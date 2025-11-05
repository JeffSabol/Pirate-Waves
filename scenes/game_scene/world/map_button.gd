extends TextureRect


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ! $"../Map".is_visible_in_tree():
			$"../Map".show()
			$"../MapBorder".show()
		else:
			$"../Map".hide()
			$"../MapBorder".hide()
