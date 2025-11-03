extends Control

var town_ui: Control = null
var trade_ui: Control = null
var shipyard_ui: Control = null

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
