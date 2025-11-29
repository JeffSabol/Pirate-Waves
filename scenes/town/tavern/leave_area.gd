extends ColorRect

var pulse_tween: Tween

func _on_mouse_entered():
	$"..".texture = load("res://assets/ui/town/tavern/TavernBackgroundLeave.png")
	$Doorcreak.play()
	$"../../DoorLight".show()

func _on_mouse_exited():
	$"..".texture = load("res://assets/ui/town/tavern/TavernBackgroundEmpty.png")
	$Doorcreak.stop()
	$"../../DoorLight".hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		$"../../..".queue_free()
		ProjectMusicController.play_stream(load("res://assets/sfx/LOOP_BackgroundIsland1SFX.wav"))
