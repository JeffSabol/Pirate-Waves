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
	update_stats()
	if player.can_fire_left:
		$Fire/HBoxContainer/FireLeftButton.disabled = false
	else:
		$Fire/HBoxContainer/FireLeftButton.disabled = true
	if player.can_fire_right:
		$Fire/HBoxContainer/FireRightButton.disabled = false
	else:
		$Fire/HBoxContainer/FireRightButton.disabled = true

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

func update_stats():
	#$SailStats/HP.text = "HP:                   %d" % player.hp
	$Stats/Guns.text = str(player.guns)
	$Stats/Knots.text = str(player.knots)
	$Gold/Gold.text = str(player.gold)

func _on_map_button_pressed():
	pass # Replace with function body.


func _on_fire_left_button_pressed():
	player.fire_left_guns()


func _on_fire_right_button_pressed():
	player.fire_right_guns()

func _on_left_button_down():
	Input.action_press("ui_left")

func _on_left_button_up():
	Input.action_release("ui_left")

func _on_right_button_down(): 
	Input.action_press("ui_right")

func _on_right_button_up():
	Input.action_release("ui_right")

func _on_up_button_down():
	Input.action_press("ui_up")

func _on_up_button_up():
	Input.action_release("ui_up")

func _on_down_button_down():
	Input.action_press("ui_down")

func _on_down_button_up():
	Input.action_release("ui_down")

func _on_switch_control_layout_pressed():
	print("switch control pressed")
	if $Fire.visible:
		$SwitchControlLayout.texture_normal = load("res://assets/ui/worldui/buttons/phone.png")
		$SwitchControlLayout.texture_pressed = load("res://assets/ui/worldui/buttons/phone_pressed.png")
		$Fire.hide()
		$Dpad.hide()
	else:
		$SwitchControlLayout.texture_normal = load("res://assets/ui/worldui/buttons/computer.png")
		$SwitchControlLayout.texture_pressed = load("res://assets/ui/worldui/buttons/computer_pressed.png")
		$Fire.show()
		$Dpad.show()

func _on_mobile_pause_button_button_down():
	print("print!")
	Input.action_press("ui_cancel")
