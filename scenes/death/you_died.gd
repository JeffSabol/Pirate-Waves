extends Control

func _unhandled_input(event: InputEvent) -> void:
	await get_tree().create_timer(3).timeout
	if event is InputEventKey and event.pressed and get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu_with_animations.tscn")
	elif event is InputEventMouseButton and event.pressed and get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu_with_animations.tscn")
