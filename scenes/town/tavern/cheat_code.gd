extends ColorRect

var click_count: int = 0

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_count += 1

		if click_count >= 5:
			print("cheat code activated")
			$CheatCode.play()
			$"../../../../PlayerBoat".grog_drink += 1
			$"../../../../PlayerBoat".siren_drink += 1
			$"../../../../PlayerBoat".captain_drink += 1
			click_count = 0
