extends ColorRect

func _on_mouse_entered():
	$LeaveGlow.show()

func _on_mouse_exited():
	$LeaveGlow.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var fade := $"../FadeRect"
		fade.fade_out(1.0, func():
			# This runs AFTER the fade completes
			$"../../../../PlayerBoat".controls_enabled = true
			$"../../../../GameUI".show_world_ui()
			$"../../".queue_free()
		)
