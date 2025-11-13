extends TextureRect

var dragging := false
var drag_offset := Vector2.ZERO

func _ready():
	$GoldBalance.text = str($"../../../../PlayerBoat".gold)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			# Store how far inside the panel we clicked (in GLOBAL space)
			drag_offset = get_global_mouse_position() - global_position
			accept_event()
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		# Keep the same offset while we drag
		global_position = get_global_mouse_position() - drag_offset
		accept_event()

func _physics_process(delta):
	$GoldBalance.text = str($"../../../../PlayerBoat".gold)

func _on_speed_upgrade_gui_input(event):
	pass # Replace with function body.


	
