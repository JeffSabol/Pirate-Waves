extends Control

func _physics_process(_delta):
	# Player Live Updates
	# Gold
	$CanvasLayer/MenuBackground/PlayerNameLabel/PlayerGoldLabel.text = str($"../../PlayerBoat".gold)
	# Fish
	$CanvasLayer/MenuBackground/VBoxContainer/FishContainer/PlayerFishLBs.text = str($"../../PlayerBoat".fish) + " LB"
	# Rum
	$CanvasLayer/MenuBackground/VBoxContainer/RumContainer/PlayerRumLBs.text = str($"../../PlayerBoat".rum) + " LB"
	# Ore
	$CanvasLayer/MenuBackground/VBoxContainer/OreContainer/PlayerOreLBs.text = str($"../../PlayerBoat".ore) + " LB"
	# Clothes
	$CanvasLayer/MenuBackground/VBoxContainer/ClothesContainer/PlayerClothesLBs.text = str($"../../PlayerBoat".clothes) + " LB"
	
	# Merchant Live Updates
	$CanvasLayer/MenuBackground/MerchantNameLabel/MerchantGoldLabel.text = str($"../../PlayerBoat".in_town_gold)
	# Fish
	$CanvasLayer/MenuBackground/VBoxContainer/FishContainer/MerchantFishLBs.text = str($"../../PlayerBoat".in_town_fish) + " LB"
	# Rum
	$CanvasLayer/MenuBackground/VBoxContainer/RumContainer/MerchantRumLBs.text = str($"../../PlayerBoat".in_town_rum) + " LB"
	# Ore
	$CanvasLayer/MenuBackground/VBoxContainer/OreContainer/MerchantOreLBs.text = str($"../../PlayerBoat".in_town_ore) + " LB"
	# Clothes
	$CanvasLayer/MenuBackground/VBoxContainer/ClothesContainer/MerchantClothesLBs.text = str($"../../PlayerBoat".in_town_clothes) + " LB"

func _on_leave_pressed():
	queue_free()
