
extends TextureButton


func _on_pressed():
	if  !$"../Inventory".is_visible_in_tree():
		$"../Inventory".show()
		
	else:
		$"../Inventory".hide()
		
