extends Control

@export var float_amplitude: float = 6.0
@export var float_period: float = 3.0

@export var wiggle_amplitude: float = 2.5
@export var wiggle_period: float = 0.35
@export var wiggle_loops: int = 2

var initial_extra_spacing: float = 1000

var drinks: Array[TextureRect] = []
var state: Dictionary = {}  # node -> {dragging, drag_offset, base_pos, time_offset, wiggle_tween}

func _ready() -> void:
	randomize()

	var hbox := $HBoxContainer

	for n in ["SirensWhisper", "Grog", "CaptainsResolve"]:
		var d := hbox.get_node_or_null(n)
		if d and d is TextureRect:
			drinks.append(d)

	await get_tree().process_frame

	var index := 0
	for d in drinks:
		var gp: Vector2 = d.global_position
		var old_size: Vector2 = d.size
		var old_min_size: Vector2 = d.custom_minimum_size
		var old_scale: Vector2 = d.scale

		d.get_parent().remove_child(d)
		add_child(d)

		d.set_anchors_preset(Control.PRESET_TOP_LEFT)
		d.set_offsets_preset(Control.PRESET_TOP_LEFT)

		d.position = (gp - self.global_position) + Vector2(index * initial_extra_spacing, 0)

		d.size = old_size
		d.custom_minimum_size = old_min_size if old_min_size != Vector2.ZERO else old_size
		d.scale = old_scale
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

		d.mouse_filter = Control.MOUSE_FILTER_STOP
		d.gui_input.connect(_on_drink_gui_input.bind(d))
		d.mouse_entered.connect(_on_drink_mouse_entered.bind(d))
		d.mouse_exited.connect(_on_drink_mouse_exited.bind(d))

		state[d] = {
			"dragging": false,
			"drag_offset": Vector2.ZERO,
			"base_pos": d.position,
			"time_offset": randf() * TAU,
			"wiggle_tween": null
		}

		index += 1

	set_process(true)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0

	for d in drinks:
		if !is_instance_valid(d):
			continue

		var st: Dictionary = state[d]

		if st["dragging"]:
			st["base_pos"] = d.position
			state[d] = st
			continue

		var base: Vector2 = st["base_pos"] as Vector2
		var time_offset: float = st["time_offset"] as float
		var yoff := sin((t * TAU / float_period) + time_offset) * float_amplitude

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

			_stop_wiggle(d)
			state[d] = st

			d.move_to_front()
			accept_event()
		else:
			st["dragging"] = false
			st["base_pos"] = d.position
			state[d] = st
			accept_event()

	elif event is InputEventMouseMotion and st["dragging"]:
		var drag_offset: Vector2 = st["drag_offset"] as Vector2
		d.global_position = mouse_g - drag_offset
		st["base_pos"] = d.position
		state[d] = st
		accept_event()


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
