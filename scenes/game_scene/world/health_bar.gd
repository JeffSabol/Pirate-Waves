extends TextureProgressBar

@onready var player := get_node("../../../PlayerBoat")

func _ready() -> void:
	player.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(player.hp, player.max_hp)

func _on_hp_changed(hp, max_hp):
	max_value = max_hp
	value = hp
