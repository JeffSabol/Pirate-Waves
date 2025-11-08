extends ColorRect

func _on_mouse_entered():
	$TradeGlow.show()

func _on_mouse_exited():
	$TradeGlow.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		$"../../../../GameUI".show_trade_ui()
