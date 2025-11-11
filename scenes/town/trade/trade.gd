extends Control

func _physics_process(delta):
	$CanvasLayer/MenuBackground/PlayerNameLabel/PlayerGoldLabel.text = str($"../../PlayerBoat".gold)
	print($"../../PlayerBoat".in_town_name)
	print($"../../PlayerBoat".in_town_gold)
	$CanvasLayer/MenuBackground/MerchantNameLabel/MerchantGoldLabel.text = str($"../../PlayerBoat".in_town_gold)

func _on_leave_pressed():
	queue_free()
