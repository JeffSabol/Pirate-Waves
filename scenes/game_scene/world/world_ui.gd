# Godot 4.5 – MapUI.gd
extends Control

@export var world_size := Vector2(18100.0, 11100.0)  # your water area size
# Where is (0,0) of your world relative to that water rectangle?
# If your world origin is at the TOP-LEFT of the water, leave this as Vector2.ZERO.
# If your world origin is at the CENTER of the water, set to -world_size * 0.5.
@export var world_top_left := Vector2.ZERO

@export_node_path("Node2D") var player_path

@onready var player: Node2D      = get_node(player_path)
@onready var map_tex: TextureRect = $MapTexture
@onready var ship_icon: Control   = $ShipIcon

func _process(_dt: float) -> void:
	update_ship_marker()

func update_ship_marker() -> void:
	if player == null:
		return

	var world_pos  := player.global_position
	var world_local := world_pos - world_top_left

	var map_draw_size := map_tex.size           # should be 605×735 at runtime
	var scale         := map_draw_size / world_size
	var map_local     := world_local * scale    # now in MapTexture's local pixels

	var map_ui_pos := map_tex.position + map_local
	map_ui_pos -= ship_icon.size * 0.5          # center the icon on the point

	var min_p := map_tex.position
	var max_p := map_tex.position + map_draw_size - ship_icon.size
	ship_icon.position = map_ui_pos.clamp(min_p, max_p)

	ship_icon.rotation = player.rotation
