extends Control

func _ready():
	# disable player controls
	get_tree().call_group("player", "disable_controls")
	# make sure the UI grabs keyboard focus so arrows/ESC go here
	grab_focus()

func _exit_tree():
	# re-enable when UI is removed
	get_tree().call_group("player", "enable_controls")
	$"../../GameUI".show_world_ui()
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
