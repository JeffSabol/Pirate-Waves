extends ColorRect

var pulse_tween: Tween

func _on_mouse_entered():
	print("mouse entered leave area")
	# Stop any previous tween (in case of re-entry)
	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()

	# Create a looping tween that brightens and dims slowly
	pulse_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(self, "color", Color(1.0, 1.0, 0.0, 0.05), 1) # brighten over 1.5 sec
	pulse_tween.tween_property(self, "color", Color(0.0, 0.0, 0.0, 0.0), 1) # dim over 1.5 sec
	$FireplaceSound.play()
	
func _on_mouse_exited():
	print("mouse exited leave area")
	# Stop the pulse tween and fade out gently
	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()

	var fade_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(self, "color", Color(0, 0, 0, 0), 1.0) # fade out slower
	$FireplaceSound.stop()


func _on_gui_input(event):
	print("leave!")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		$"../../..".queue_free()
