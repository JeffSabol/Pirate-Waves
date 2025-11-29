extends Control

@onready var tavern_glow: CanvasItem   = $CanvasLayer/TavernClickZone/TavernGlow
@onready var trade_glow: CanvasItem    = $CanvasLayer/TradeClickZone/TradeGlow
@onready var shipyard_glow: CanvasItem = $CanvasLayer/ShipyardClickZone/ShipyardGlow
@onready var leave_glow: CanvasItem    = $CanvasLayer/LeaveClickZone/LeaveGlow

# Optional: if you later want to "activate" (simulate a click),
# you can grab the zones too:
@onready var tavern_zone   = $CanvasLayer/TavernClickZone
@onready var trade_zone    = $CanvasLayer/TradeClickZone
@onready var shipyard_zone = $CanvasLayer/ShipyardClickZone
@onready var leave_zone    = $CanvasLayer/LeaveClickZone

# Will be filled in _ready()
var glows: Array[CanvasItem]

# 0 = Tavern (left), 1 = Trade (middle), 2 = Shipyard (right), 3 = Leave (bottom)
var current_index: int = 0
var last_top_row_index: int = 0  # remembers last selection in the top row when you go down to "Leave"


func _ready() -> void:
	glows = [tavern_glow, trade_glow, shipyard_glow, leave_glow]
	update_selection()


func _process(_delta: float) -> void:
	handle_move_input()
	handle_accept_input()


func handle_move_input() -> void:
	# LEFT / RIGHT
	if Input.is_action_just_pressed("ui_left"):
		move_horizontal(-1)
	elif Input.is_action_just_pressed("ui_right"):
		move_horizontal(1)

	# UP / DOWN
	if Input.is_action_just_pressed("ui_up"):
		move_vertical(-1)
	elif Input.is_action_just_pressed("ui_down"):
		move_vertical(1)


func move_horizontal(dir: int) -> void:
	# If currently on Leave and you press left/right, snap back to last top-row slot first
	if current_index == 3:
		current_index = last_top_row_index

	if current_index <= 2:
		# 👇 key change: explicitly int-typed
		var new_index: int = clampi(current_index + dir, 0, 2)
		if new_index != current_index:
			current_index = new_index
			last_top_row_index = current_index
			update_selection()


func move_vertical(dir: int) -> void:
	if dir > 0:
		# DOWN: go from top row (0–2) to Leave (3)
		if current_index != 3:
			last_top_row_index = current_index
			current_index = 3
			update_selection()
	else:
		# UP: go from Leave back to whatever top-row index we came from
		if current_index == 3:
			current_index = last_top_row_index
			update_selection()


func update_selection() -> void:
	for i in range(glows.size()):
		glows[i].visible = (i == current_index)


func handle_accept_input() -> void:
	# Hook this up if you want Enter/Space/Gamepad A/etc. to "press" the current menu
	# (make sure "ui_accept" is bound in Input Map).
	if not Input.is_action_just_pressed("ui_accept"):
		return

	match current_index:
		0:
			# Tavern selected
			$"../../GameUI".show_tavern_ui()
		1:
			# Trade selected
			$"../../GameUI".show_trade_ui()
		2:
			# Shipyard selected
			$"../../GameUI".show_shipyard_ui()
		3:
			# Leave selected
			$"../../GameUI".show_world_ui()
			$"../../PlayerBoat".controls_enabled = true
			$".".queue_free()
