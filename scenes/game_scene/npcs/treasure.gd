extends Node2D

@export_enum("Gold", "Fish", "Rum", "Ore", "Clothes")
var treasure_type: String = "Gold"

@export_enum("Small", "Medium", "Large")
var treasure_size: String = "Small"

# Explicitly typed dictionaries to avoid Variant inference errors
const LOOT_TABLE: Dictionary[String, Vector2i] = {
	"Gold": Vector2i(5, 25),
	"Fish": Vector2i(1, 6),
	"Rum": Vector2i(1, 3),
	"Ore": Vector2i(2, 8),
	"Clothes": Vector2i(1, 4),
}

const SIZE_MULTIPLIER: Dictionary[String, float] = {
	"Small": 1.0,
	"Medium": 1.75,
	"Large": 3.0,
}

func roll_loot_amount() -> int:
	var base_range: Vector2i = LOOT_TABLE.get(treasure_type, Vector2i(1, 1))
	var amount := randi_range(base_range.x, base_range.y)
	amount = int(amount * SIZE_MULTIPLIER.get(treasure_size, 1.0))
	return max(amount, 1)

func _on_pickup_zone_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var amount := roll_loot_amount()
	body.add_loot(treasure_type, amount)
	$PickupSound.play()
	print("Picked up %d %s" % [amount, treasure_type])
	# TODO wire into inventory
	queue_free()
