extends TextureButton

func _input(_event):
	pass


func _on_pressed():
	# Keep your mouse toggle working too
	if not $"../Inventory".is_visible_in_tree():
		$"../Inventory".show()
	else:
		$"../Inventory".hide()
