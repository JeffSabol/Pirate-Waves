extends Control

var town_ui: Control = null

func show_town_ui():
	print("Showing town UI")
	town_ui = preload("res://scenes/town/Town.tscn").instantiate()
	add_child(town_ui)
