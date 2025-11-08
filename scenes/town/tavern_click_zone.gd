extends ColorRect

func _on_mouse_entered():
	$TavernGlow.show()

func _on_mouse_exited():
	$TavernGlow.hide()


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("load tavern!")
		$"../../../../GameUI".show_tavern_ui()
