extends Control

@export var float_amplitude: float = 6.0
@export var float_period: float = 3.0

@export var wiggle_amplitude: float = 5.0
@export var wiggle_period: float = 0.35
@export var wiggle_loops: int = 2

@export var initial_extra_spacing: float = 1000
# pixels moved before it's considered a drag
@export var click_threshold: float = 4.0
@onready var bottle_clink: AudioStreamPlayer = $BottleClink

var drinks: Array[TextureRect] = []
var state: Dictionary = {}  # node -> state dict

var clink_sfx: Array[AudioStream] = [
	preload("res://assets/sfx/bottle_clink1.mp3"),
	preload("res://assets/sfx/bottle_clink2.mp3"),
	preload("res://assets/sfx/bottle_clink3.mp3"),
	preload("res://assets/sfx/bottle_clink4.mp3"),
	preload("res://assets/sfx/bottle_clink5.mp3"),
]


func _ready() -> void:
	randomize()

	var hbox := $HBoxContainer

	# Get the drink icons from the HBox
	for n in ["SirensWhisper", "Grog", "CaptainsResolve"]:
		var d := hbox.get_node_or_null(n)
		if d and d is TextureRect:
			drinks.append(d)

	# Let the HBox finish its layout
	await get_tree().process_frame

	var index := 0
	for d in drinks:
		# Save screen-space info BEFORE removing from HBox
		var gp: Vector2 = d.global_position
		var old_size: Vector2 = d.size
		var old_min_size: Vector2 = d.custom_minimum_size
		var old_scale: Vector2 = d.scale

		# Remove from HBox so layout no longer controls them
		d.get_parent().remove_child(d)
		add_child(d)

		# Reset anchors so they don't collapse in new parent
		d.set_anchors_preset(Control.PRESET_TOP_LEFT)
		d.set_offsets_preset(Control.PRESET_TOP_LEFT)

		# Convert global -> local, then add spacing so they don't stack
		d.position = (gp - self.global_position) + Vector2(index * initial_extra_spacing, 0)

		# Restore how they looked inside the HBox (size/scale)
		d.size = old_size
		d.custom_minimum_size = old_min_size if old_min_size != Vector2.ZERO else old_size
		d.scale = old_scale
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

		# Input + hover setup
		d.mouse_filter = Control.MOUSE_FILTER_STOP
		d.gui_input.connect(_on_drink_gui_input.bind(d))
		d.mouse_entered.connect(_on_drink_mouse_entered.bind(d))
		d.mouse_exited.connect(_on_drink_mouse_exited.bind(d))

		# State per drink
		state[d] = {
			"dragging": false,
			"drag_offset": Vector2.ZERO,  # global offset for smooth dragging
			"base_pos": d.position,       # float/wiggle center
			"time_offset": randf() * TAU, # desync float
			"wiggle_tween": null,

			# click vs drag detection
			"press_pos": Vector2.ZERO,
			"was_drag": false
		}

		index += 1

	set_process(true)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0

	for d in drinks:
		if !is_instance_valid(d):
			continue

		var st: Dictionary = state[d]

		# No floating while dragging
		if st["dragging"]:
			st["base_pos"] = d.position
			state[d] = st
			continue

		var base: Vector2 = st["base_pos"] as Vector2
		var time_offset: float = st["time_offset"] as float
		var yoff := sin((t * TAU / float_period) + time_offset) * float_amplitude

		# Only adjust Y so wiggle X tween isn't overwritten
		var p := d.position
		p.y = base.y + yoff
		d.position = p


func _on_drink_gui_input(event: InputEvent, d: Control) -> void:
	var st: Dictionary = state[d]
	var mouse_g := get_global_mouse_position()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			st["dragging"] = true
			st["drag_offset"] = mouse_g - d.global_position

			# click tracking start
			st["press_pos"] = mouse_g
			st["was_drag"] = false

			_stop_wiggle(d)
			state[d] = st

			d.move_to_front()
			accept_event()

		else:
			# On release: if we didn't drag, treat as click
			if !(st["was_drag"] as bool):
				_on_drink_clicked(d)

			st["dragging"] = false
			st["base_pos"] = d.position
			state[d] = st
			accept_event()

	elif event is InputEventMouseMotion and st["dragging"]:
		# If mouse moved enough, mark as drag
		var press_pos: Vector2 = st["press_pos"] as Vector2
		if !st["was_drag"] and press_pos.distance_to(mouse_g) >= click_threshold:
			st["was_drag"] = true

		var drag_offset: Vector2 = st["drag_offset"] as Vector2
		d.global_position = mouse_g - drag_offset

		st["base_pos"] = d.position
		state[d] = st
		accept_event()


func _on_drink_clicked(d: Control) -> void:
	var player := $"../../../../PlayerBoat"
	print("Player selected %s" % d.name)
	print(str(player.gold))
	print(d.name)

	var bought := false

	if d.name == "SirensWhisper" and player.gold >= 40:
		player.siren_drink += 1
		player.gold -= 40
		bought = true
	elif d.name == "Grog" and player.gold >= 30:
		player.grog_drink += 1
		player.gold -= 30
		bought = true
	elif d.name == "CaptainsResolve" and player.gold >= 25:
		player.captain_drink += 1
		player.gold -= 25
		bought = true

	if bought:
		_play_random_clink()
		print("got here")
	else:
		player.get_node("NotEnoughSFX").play()
		pass

func _on_drink_mouse_entered(d: Control) -> void:
	var st: Dictionary = state[d]
	if st["dragging"]:
		return
	_start_wiggle(d)


func _on_drink_mouse_exited(d: Control) -> void:
	_stop_wiggle(d)


func _start_wiggle(d: Control) -> void:
	_stop_wiggle(d)

	var st: Dictionary = state[d]
	var base: Vector2 = st["base_pos"] as Vector2

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tw.tween_property(d, "position:x", base.x - wiggle_amplitude, wiggle_period * 0.5)
	tw.tween_property(d, "position:x", base.x + wiggle_amplitude, wiggle_period)
	tw.tween_property(d, "position:x", base.x, wiggle_period * 0.5)
	tw.set_loops(wiggle_loops)

	st["wiggle_tween"] = tw
	state[d] = st


func _stop_wiggle(d: Control) -> void:
	var st: Dictionary = state[d]
	var wt = st["wiggle_tween"]

	if wt != null and wt is Tween and wt.is_running():
		wt.kill()

	st["wiggle_tween"] = null
	d.position.x = (st["base_pos"] as Vector2).x
	state[d] = st

func _play_random_clink() -> void:
	if clink_sfx.is_empty():
		return
	bottle_clink.stream = clink_sfx[randi() % clink_sfx.size()]
	bottle_clink.play()
