extends Control

@export var float_amplitude: float = 6.0
@export var float_period: float = 3.0

@export var wiggle_amplitude: float = 5.0
@export var wiggle_period: float = 0.35
@export var wiggle_loops: int = 2

@export var initial_extra_spacing: float = 1000
@export var click_threshold: float = 4.0

var items: Array[TextureRect] = []
var item_state: Dictionary = {}  # item -> state dict


func _ready() -> void:
	randomize()

	var hbox: HBoxContainer = $HBoxContainer

	# Updated item names
	for n in ["Hammer", "Compass", "Spyglass"]:
		var it := hbox.get_node_or_null(n)
		if it and it is TextureRect:
			items.append(it)

	await get_tree().process_frame

	var index := 0
	for it in items:
		var gp: Vector2 = it.global_position
		var old_size: Vector2 = it.size
		var old_min_size: Vector2 = it.custom_minimum_size
		var old_scale: Vector2 = it.scale

		it.get_parent().remove_child(it)
		add_child(it)

		it.set_anchors_preset(Control.PRESET_TOP_LEFT)
		it.set_offsets_preset(Control.PRESET_TOP_LEFT)

		it.position = (gp - self.global_position) + Vector2(index * initial_extra_spacing, 0)

		it.size = old_size
		it.custom_minimum_size = old_min_size if old_min_size != Vector2.ZERO else old_size
		it.scale = old_scale
		it.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

		it.mouse_filter = Control.MOUSE_FILTER_STOP
		it.gui_input.connect(_on_item_gui_input.bind(it))
		it.mouse_entered.connect(_on_item_mouse_entered.bind(it))
		it.mouse_exited.connect(_on_item_mouse_exited.bind(it))

		item_state[it] = {
			"dragging": false,
			"drag_offset": Vector2.ZERO,
			"base_pos": it.position,
			"time_offset": randf() * TAU,
			"wiggle_tween": null,
			"press_pos": Vector2.ZERO,
			"was_drag": false
		}

		index += 1

	set_process(true)


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0

	for it in items:
		if !is_instance_valid(it):
			continue

		var st: Dictionary = item_state[it]

		if st["dragging"] as bool:
			st["base_pos"] = it.position
			item_state[it] = st
			continue

		var base: Vector2 = st["base_pos"] as Vector2
		var time_offset: float = st["time_offset"] as float
		var offs: float = sin((t * TAU / float_period) + time_offset) * float_amplitude

		var p: Vector2 = it.position
		p.y = base.y + offs
		it.position = p


func _on_item_gui_input(event: InputEvent, it: Control) -> void:
	var st: Dictionary = item_state[it]
	var mouse_g: Vector2 = get_global_mouse_position()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			st["dragging"] = true
			st["drag_offset"] = mouse_g - it.global_position
			st["press_pos"] = mouse_g
			st["was_drag"] = false

			_stop_wiggle(it)
			item_state[it] = st

			it.move_to_front()
			accept_event()
		else:
			if !(st["was_drag"] as bool):
				_on_item_clicked(it)

			st["dragging"] = false
			st["base_pos"] = it.position
			item_state[it] = st
			accept_event()

	elif event is InputEventMouseMotion and (st["dragging"] as bool):
		var press_pos: Vector2 = st["press_pos"] as Vector2
		if !(st["was_drag"] as bool) and press_pos.distance_to(mouse_g) >= click_threshold:
			st["was_drag"] = true

		var drag_offset: Vector2 = st["drag_offset"] as Vector2
		it.global_position = mouse_g - drag_offset

		st["base_pos"] = it.position
		item_state[it] = st
		accept_event()


func _on_item_clicked(it: Control) -> void:
	var player := $"../../../../PlayerBoat"

	var bought := false

	# updated item prices + counters
	if it.name == "Spyglass" and player.gold >= 50:
		print("buy spyglass")
		#player.spyglass_item += 1
		player.gold -= 50
		bought = true
	elif it.name == "Hammer" and player.gold >= 10:
		print("buy hammer")
		#player.hammer_item += 1
		player.gold -= 10
		bought = true
	elif it.name == "Compass" and player.gold >= 80:
		print("buy compass")
		#player.compass_item += 1
		player.gold -= 80
		bought = true

	if !bought:
		player.get_node("NotEnoughSFX").play()


func _on_item_mouse_entered(it: Control) -> void:
	var st: Dictionary = item_state[it]
	if st["dragging"] as bool:
		return
	_start_wiggle(it)


func _on_item_mouse_exited(it: Control) -> void:
	_stop_wiggle(it)


func _start_wiggle(it: Control) -> void:
	_stop_wiggle(it)

	var st: Dictionary = item_state[it]
	var base: Vector2 = st["base_pos"] as Vector2

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tw.tween_property(it, "position:x", base.x - wiggle_amplitude, wiggle_period * 0.5)
	tw.tween_property(it, "position:x", base.x + wiggle_amplitude, wiggle_period)
	tw.tween_property(it, "position:x", base.x, wiggle_period * 0.5)
	tw.set_loops(wiggle_loops)

	st["wiggle_tween"] = tw
	item_state[it] = st


func _stop_wiggle(it: Control) -> void:
	var st: Dictionary = item_state[it]
	var tw = st["wiggle_tween"]

	if tw != null and tw is Tween and tw.is_running():
		tw.kill()

	st["wiggle_tween"] = null
	it.position.x = (st["base_pos"] as Vector2).x
	item_state[it] = st


func _toggle_card(item_name: String) -> void:
	var target: Control = null
	print("items: " + str(items))
	for it in items:
		if is_instance_valid(it) and it.name == item_name:
			target = it
			break

	if target == null:
		push_warning("Item not found: %s" % item_name)
		return

	target.visible = !target.visible
	if target.visible:
		target.move_to_front()


func _on_spyglass_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_card("Spyglass")
		accept_event()


func _on_hammer_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_card("Hammer")
		accept_event()


func _on_compass_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_card("Compass")
		accept_event()
