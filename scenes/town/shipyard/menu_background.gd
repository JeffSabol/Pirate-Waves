extends TextureRect

var dragging := false
var drag_offset := Vector2.ZERO

func _ready():
	$GoldBalance.text = str($"../../../../PlayerBoat".gold)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			# Store how far inside the panel we clicked (in GLOBAL space)
			drag_offset = get_global_mouse_position() - global_position
			accept_event()
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		# Keep the same offset while we drag
		global_position = get_global_mouse_position() - drag_offset
		accept_event()

func _physics_process(delta):
	$GoldBalance.text = str($"../../../../PlayerBoat".gold)

func _on_speed_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_speed()

func _on_turning_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_turning()

func _on_hull_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_hull()

func _on_guns_upgrade_btn_pressed():
	$"../../../../PlayerBoat".upgrade_hull()


func _on_exit_click_zone_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		$"./../../".queue_free()

func _on_repair_click_zone_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		var player = $"../../../../PlayerBoat"
		
		var missing_hp = player.max_hp - player.hp
		if missing_hp <= 0:
			print("Ship already fully repaired.")
			$"../../../../PlayerBoat/NotEnoughSFX".play()
			return
		
		var repair_cost = missing_hp  # 1 gold per 1 HP
		
		# If not enough gold, repair partially
		var amount_affordable = min(player.gold, missing_hp)
		
		if amount_affordable <= 0:
			print("Not enough gold to repair.")
			$"../../../../PlayerBoat/NotEnoughSFX".play()
			return
		
		# Apply repair
		player.hp += amount_affordable
		player.gold -= amount_affordable
		
		print("Repaired ", amount_affordable, " HP for ", amount_affordable, " gold.")
