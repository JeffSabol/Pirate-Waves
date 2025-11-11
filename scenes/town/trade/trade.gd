extends Control

func _physics_process(delta):
	$CanvasLayer/MenuBackground/PlayerNameLabel/PlayerGoldLabel.text = str($"../../PlayerBoat".gold)

func _on_leave_pressed():
	queue_free()
