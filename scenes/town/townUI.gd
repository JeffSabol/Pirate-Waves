extends Control

func _ready():
	# disable player controls
	get_tree().call_group("player", "disable_controls")
	# make sure the UI grabs keyboard focus so arrows/ESC go here
	grab_focus()

func _exit_tree():
	# re-enable when UI is removed
	get_tree().call_group("player", "enable_controls")
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		
func _on_trade_button_pressed():
	print("Pressed trade button")
	$"../../GameUI".show_trade_ui()
	
func _on_shipyard_button_pressed():
	print("Pressed shipyard button")
	$"../../GameUI".show_shipyard_ui()

func _on_tavern_button_pressed():
	print("Pressed tavern button")
	$"../../GameUI".show_tavern_ui()

func _on_quests_button_pressed():
	print("Pressed quests button")

func _on_leave_button_pressed():
	print("Pressed leave button")
	$"../../PlayerBoat/AudioStreamPlayer2D".play()
	queue_free()
	
