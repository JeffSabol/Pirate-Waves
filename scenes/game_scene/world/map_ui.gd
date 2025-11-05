extends Control

@export var world_size: Vector2 = Vector2(18100.0, 11100.0)
@export var world_top_left: Vector2 = Vector2.ZERO

@onready var player: Node2D = get_node("../../PlayerBoat")
@onready var map_tex: TextureRect = $Map
@onready var ship_icon: Control = $ShipIcon

func _process(_dt: float) -> void:
	if not is_instance_valid(player):
		return
	update_ship_marker()

func update_ship_marker() -> void:
	var world_pos: Vector2 = player.global_position
	var world_local: Vector2 = world_pos - world_top_left

	var map_draw_pos: Vector2 = map_tex.position
	var map_draw_size: Vector2 = map_tex.size
	var scale: Vector2 = map_draw_size / world_size
	var map_local: Vector2 = (world_local * scale)/3

	var map_ui_pos: Vector2 = map_draw_pos + map_local - (ship_icon.size * 0.5)

	# Clamp so it stays on the map
	map_ui_pos = map_ui_pos.clamp(
		map_draw_pos,
		map_draw_pos + map_draw_size - ship_icon.size
	)

	ship_icon.position = map_ui_pos
