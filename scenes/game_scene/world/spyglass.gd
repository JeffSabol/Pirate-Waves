extends TextureButton

@onready var player: Node2D = $"../../../../PlayerBoat"

@onready var camera: Camera2D = $"../../../../PlayerBoat/Camera2D"

var _base_texture: Texture2D
var _last_can_use: bool = false

var _is_active: bool = false      # zoomed out
var _is_animating: bool = false   # currently tweening zoom
var _base_zoom: Vector2
var _tween: Tween = null

# Zoom tuning
const ZOOM_MULTIPLIER: float = 2.0
const ZOOM_DURATION: float = 0.6
const ZOOM_HOLD_TIME: float = 5.0


func _ready() -> void:
	# Remember original button texture as the "normal" spyglass icon
	_base_texture = texture_normal
	if _base_texture == null:
		push_warning("Spyglass button: texture_normal is null. Assign a base texture in the inspector.")

	# Try to auto-find a camera if not wired in the inspector
	if camera == null:
		var scene := get_tree().current_scene
		if scene:
			var found_cam := scene.find_child("Camera2D", true, false)
			if found_cam is Camera2D:
				camera = found_cam

	tooltip_text = "Spyglass: not owned."

	_update_visual_state()


func _process(delta: float) -> void:
	if !is_instance_valid(player):
		return

	_update_visual_state()


func _update_visual_state() -> void:
	if !is_instance_valid(player):
		return

	# --- Hide entire button if player does not own the spyglass ---
	if !player.has_spyglass:
		visible = false
		disabled = true
		tooltip_text = "Spyglass: not owned.\nBuy it in the shop."
		return
	else:
		visible = true

	var has_camera: bool = is_instance_valid(camera)

	# Can use if:
	# - we own the spyglass
	# - we have a camera
	# - not currently zooming / holding
	var can_use: bool = has_camera and (not _is_active) and (not _is_animating)

	# Only react when thing changes (usable vs not)
	if can_use != _last_can_use:
		_last_can_use = can_use

		disabled = not can_use

		if can_use:
			texture_normal = _base_texture
		else:
			# You can add a grey texture here later if you want
			texture_normal = _base_texture

		_play_fade(can_use)

	_update_tooltip(can_use, has_camera)


func _play_fade(can_use: bool) -> void:
	var tween := create_tween()

	if can_use:
		# Fade to full strength when becoming usable
		modulate = Color(1, 1, 1, 0.6)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.18)
	else:
		# Slightly dim when not usable (during zoom)
		modulate = Color(1, 1, 1, 1.0)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0.7), 0.18)


func _update_tooltip(can_use: bool, has_camera: bool) -> void:
	if !is_instance_valid(player):
		return

	if !player.has_spyglass:
		tooltip_text = "Spyglass: not owned.\nBuy it in the shop."
		return

	if !has_camera:
		tooltip_text = "Spyglass owned,\nbut no camera is set."
		return

	if _is_active or _is_animating:
		tooltip_text = "Spyglass active...\nZoomed out for scouting."
	else:
		tooltip_text = "Spyglass ready.\nClick to zoom out for %ds." % int(ZOOM_HOLD_TIME)


func _on_pressed() -> void:
	print("activate spyglass!")
	if !is_instance_valid(player):
		return
	if !player.has_spyglass:
		return
	if !is_instance_valid(camera):
		return

	# Don’t allow re-triggering while active or animating
	if _is_active or _is_animating:
		return

	_start_spyglass()


func _start_spyglass() -> void:
	if !is_instance_valid(camera):
		return

	_is_animating = true
	_is_active = false

	# Store base zoom so we can restore exactly
	_base_zoom = camera.zoom
	var target_zoom: Vector2 = _base_zoom / ZOOM_MULTIPLIER

	# Kill any previous tween just in case
	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(camera, "zoom", target_zoom, ZOOM_DURATION)
	_tween.finished.connect(_on_zoom_out_done)


func _on_zoom_out_done() -> void:
	_is_animating = false
	_is_active = true

	# Hold zoom for a bit, then go back
	var timer := get_tree().create_timer(ZOOM_HOLD_TIME)
	timer.timeout.connect(_start_zoom_back)


func _start_zoom_back() -> void:
	if !is_instance_valid(camera):
		_is_active = false
		_is_animating = false
		return

	_is_animating = true

	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(camera, "zoom", _base_zoom, ZOOM_DURATION)
	_tween.finished.connect(_on_zoom_back_done)


func _on_zoom_back_done() -> void:
	_is_animating = false
	_is_active = false
