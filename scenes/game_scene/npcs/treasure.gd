extends Node2D

@export_enum("Gold")
#@export_enum("Gold", "Fish", "Rum", "Ore", "Clothes")
var treasure_type: String = "Gold"

@export_enum("Small", "Medium", "Large")
var treasure_size: String = "Small"

@export var FloatingTextScene: PackedScene

const LOOT_TABLE: Dictionary[String, Vector2i] = {
	"Gold": Vector2i(5, 25),
	"Fish": Vector2i(1, 6),
	"Rum": Vector2i(1, 3),
	"Ore": Vector2i(2, 8),
	"Clothes": Vector2i(1, 4),
}

const SIZE_MULTIPLIER: Dictionary[String, float] = {
	"Small": 2.0,
	"Medium": 3.75,
	"Large": 5.0,
}

var _collected: bool = false  # prevents double pick-up


func _ready() -> void:
	# Idle shine anim
	if treasure_size == "Small":
		$AnimatedSprite2D.play("small_shine")
	elif treasure_size == "Medium":
		$AnimatedSprite2D.play("medium_shine")
	else:
		$AnimatedSprite2D.play("large_shine")

	# Auto-collect after 3 seconds even if player never touches it
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(_on_auto_collect_timeout)


func roll_loot_amount() -> int:
	var base_range: Vector2i = LOOT_TABLE.get(treasure_type, Vector2i(1, 1))
	var amount := randi_range(base_range.x, base_range.y)
	amount = int(amount * SIZE_MULTIPLIER.get(treasure_size, 1.0))
	return max(amount, 1)


func _on_pickup_zone_body_entered(body: Node) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return

	await _collect(body)


func _on_auto_collect_timeout() -> void:
	if _collected:
		return

	# Grab the player manually and auto-award the loot
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	await _collect(player)


# Shared collection logic for both manual + auto pickup
func _collect(body: Node) -> void:
	_collected = true

	var amount := roll_loot_amount()
	$PickupSound.play()

	# Open animation
	if treasure_size == "Small":
		$AnimatedSprite2D.play("small_open")
	elif treasure_size == "Medium":
		$AnimatedSprite2D.play("medium_open")
	else:
		$AnimatedSprite2D.play("large_open")

	await get_tree().create_timer(1.0).timeout

	# Floating text at world position
	if FloatingTextScene:
		var ft := FloatingTextScene.instantiate() as Node2D
		ft.position = global_position
		get_tree().current_scene.add_child(ft)
		var label := "%d %s" % [amount, treasure_type]
		(ft as FloatingText).show_text(label)

	print("Picked up %d %s" % [amount, treasure_type])
	body.add_loot(treasure_type, amount)

	# Destroy animation
	if treasure_size == "Small":
		$AnimatedSprite2D.play("small_destroy")
		await get_tree().create_timer(0.9).timeout
	elif treasure_size == "Medium":
		$AnimatedSprite2D.play("medium_destroy")
		await get_tree().create_timer(1.2).timeout
	else:
		$AnimatedSprite2D.play("large_destroy")
		await get_tree().create_timer(1.2).timeout

	queue_free()
