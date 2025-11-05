extends Control

var town_ui: Control = null
var trade_ui: Control = null
var shipyard_ui: Control = null
var map_ui: Control = null


func show_town_ui():
	print("Showing town UI")
	town_ui = preload("res://scenes/town/Town.tscn").instantiate()
	add_child(town_ui)

func show_trade_ui():
	print("Showing trade UI")
	trade_ui = preload("res://scenes/town/trade/Trade.tscn").instantiate()
	add_child(trade_ui)

func show_tavern_ui():
	print("Showing tavern UI")
	trade_ui = preload("res://scenes/town/tavern/Tavern.tscn").instantiate()
	add_child(trade_ui)

func show_shipyard_ui():
	print("Showing shipyard UI")
	shipyard_ui = preload("res://scenes/town/shipyard/Shipyard.tscn").instantiate()
	add_child(shipyard_ui)

func show_map_ui():
	print("Showing the map")
	map_ui = preload("res://scenes/map/map.tscn").instantiate()
	
func hide_world_ui():
	var world_ui = $"../WorldUI"
	if world_ui:
		world_ui.queue_free()

func show_world_ui():
	var world_ui_scene = preload("res://scenes/game_scene/world/world_ui.tscn")
	var instance = world_ui_scene.instantiate()
	get_parent().add_child(instance)
