extends ColorRect

var pulse_tween: Tween

func _on_mouse_entered():
	$"..".texture = load("res://assets/ui/town/tavern/TavernBackgroundLeave.png")
	$Doorcreak.play()
	$"../BartenderArea/DoorLight".show()

func _on_mouse_exited():
	$"..".texture = load("res://assets/ui/town/tavern/TavernBackgroundEmpty.png")
	$Doorcreak.stop()
	$"../BartenderArea/DoorLight".hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		$"../../..".queue_free()


func _on_bartender_area_gui_input(event):
	pass # Replace with function body.
