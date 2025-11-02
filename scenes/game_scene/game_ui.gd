extends Control

var town_ui: Control = null

func show_town_ui():
	print("Showing town UI")
	# Only create it once
	if town_ui == null:
		town_ui = preload("res://scenes/town/Town.tscn").instantiate()
		add_child(town_ui)
	else:
		town_ui.show()
		town_ui.set_process(true)
		town_ui.set_physics_process(true)

	# Disable player controls
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.disable_controls()

func hide_town_ui():
	print("hiding town UI")
