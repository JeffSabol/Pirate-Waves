extends Control

func _physics_process(delta):
	# TODO optimize and save resource and set on opening
	$Inventory/HBoxContainer/InventoryValues2/PlayerGold.text = str($"../../PlayerBoat".gold)
	$Inventory/HBoxContainer/InventoryValues2/PlayerFish.text = str($"../../PlayerBoat".fish)
	$Inventory/HBoxContainer/InventoryValues2/PlayerRum.text = str($"../../PlayerBoat".rum)
	$Inventory/HBoxContainer/InventoryValues2/PlayerOre.text = str($"../../PlayerBoat".ore)
	$Inventory/HBoxContainer/InventoryValues2/PlayerClothes.text = str($"../../PlayerBoat".clothes)
