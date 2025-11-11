# FloatingText.gd
extends Node2D
class_name FloatingText

@export var duration := 0.8
@export var rise_pixels := 28.0

var _label: Label

func _init() -> void:
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.modulate.a = 0.0
	_label.pivot_offset = Vector2(0, 8) # slight vertical offset
	add_child(_label)

func show_text(txt: String) -> void:
	_label.text = txt

	# Start slightly below, then rise+fade
	var start_pos := position
	var end_pos := start_pos + Vector2(0, -rise_pixels)

	var tw := create_tween()
	tw.set_parallel(true)

	# Move up and fade in quickly
	tw.tween_property(self, "position", end_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "modulate:a", 1.0, 0.18)

	# After a short delay, fade out
	var tw2 := create_tween()
	tw2.tween_interval(duration * 0.55)
	tw2.tween_property(_label, "modulate:a", 0.0, duration * 0.27)

	# Cleanup
	tw2.finished.connect(queue_free)
