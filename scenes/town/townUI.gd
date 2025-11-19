extends Control

@onready var waves1 := $"CanvasLayer/Waves"
@onready var waves2 := $"CanvasLayer/Waves2"
@onready var waves3 := $"CanvasLayer/Waves3"
@onready var waves4 := $"CanvasLayer/Waves4"

@export var wave_row_duration: float = 3.25
@export var start_frame: int = 1

func _ready():
	get_tree().call_group("player", "disable_controls")
	grab_focus()

	_reset_rows([waves1, waves3])
	_show_rows([waves1, waves3])

	_wave_cycle()


func _exit_tree():
	$"../../PlayerBoat/AudioStreamPlayer2D".play()
	get_tree().call_group("player", "enable_controls")


func _show_rows(rows: Array) -> void:
	waves1.visible = false
	waves2.visible = false
	waves3.visible = false
	waves4.visible = false

	for row in rows:
		row.visible = true


func _reset_rows(rows: Array) -> void:
	for row in rows:
		for child in row.get_children():
			if "frame" in child:
				child.frame = start_frame
			if child.has_method("stop"):
				child.stop()
			if child.has_method("play"):
				child.play()


func _wave_cycle() -> void:
	await get_tree().process_frame

	var pattern = [
		[waves1, waves3],
		[waves2, waves4],
	]

	while true:
		for group in pattern:
			_reset_rows(group)
			_show_rows(group)
			await get_tree().create_timer(wave_row_duration).timeout
