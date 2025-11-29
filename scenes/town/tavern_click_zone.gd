extends ColorRect

var island_music_started := false

func _on_mouse_entered():
	$TavernGlow.show()

func _on_mouse_exited():
	$TavernGlow.hide()

func _physics_process(_delta):
	if not has_node("../../../../GameUI/Tavern"):
		if not island_music_started:
			island_music_started = true
			ProjectMusicController.play_stream(load("res://assets/sfx/LOOP_BackgroundIsland1SFX.wav"))
			

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("load tavern!")
		$"../../../../GameUI".show_tavern_ui()
		ProjectMusicController.play_stream(load("res://assets/music/tavern.mp3"))
