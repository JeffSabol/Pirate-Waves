extends TextureButton

func _input(_event):
	if Input.is_action_pressed("open_inv"):
		if not $"../Inventory".is_visible_in_tree():
			$"../Inventory".show()

	if Input.is_action_just_released("open_inv"):
		if $"../Inventory".is_visible_in_tree():
			$"../Inventory".hide()


func _on_pressed():
	# Keep your mouse toggle working too
	if not $"../Inventory".is_visible_in_tree():
		$"../Inventory".show()
	else:
		$"../Inventory".hide()
