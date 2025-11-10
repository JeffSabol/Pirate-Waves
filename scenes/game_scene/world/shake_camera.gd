# shake_camera.gd
extends Camera2D
class_name ShakeCamera

@export var max_shake_offset: float = 8.0
@export var max_shake_rotation: float = 0.03

var _rng := RandomNumberGenerator.new()
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _trauma: float = 0.0

var _base_offset: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0

func set_base(offset: Vector2, rot: float = 0.0) -> void:
	# Parent (PlayerBoat) calls this every frame to provide the “sway” baseline.
	_base_offset = offset
	_base_rotation = rot

func add_trauma(amount: float, duration: float = 0.25) -> void:
	# Call this to trigger a shake.
	_trauma = clamp(_trauma + amount, 0.0, 1.0)
	_shake_duration = max(_shake_duration, duration)
	_shake_time = 0.0

func _process(delta: float) -> void:
	if _shake_time < _shake_duration and _trauma > 0.0:
		_shake_time += delta
		var t := 1.0 - (_shake_time / _shake_duration)
		# Ease out and square for a quick snappy decay
		var amt := _trauma * t * t

		var shake_off := Vector2(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * max_shake_offset * amt

		var shake_rot := _rng.randf_range(-1.0, 1.0) * max_shake_rotation * amt

		offset = _base_offset + shake_off
		rotation = _base_rotation + shake_rot
	else:
		offset = _base_offset
		rotation = _base_rotation
		_trauma = 0.0
