extends TextureProgressBar

# We'll cache the boss health node when we find it
var boss_health: Node = null
var _attached: bool = false


func _ready() -> void:
	visible = false
	value = 0
	max_value = 100  # temp, real value comes from boss


func _process(_delta: float) -> void:
	# Already attached and valid? nothing to do.
	if _attached and is_instance_valid(boss_health):
		return

	# If we lost it (boss died / freed), hide bar and reset attachment
	if _attached and not is_instance_valid(boss_health):
		_attached = false
		boss_health = null
		visible = false
		return

	# Try to find the boss dynamically (simple jam-friendly approach)
	var scene := get_tree().current_scene
	if scene == null:
		return

	# This assumes your boss ship node is named "BossShip"
	# If your node name differs, change "BossShip" to that.
	var boss_ship := scene.find_child("BossShip", true, false)
	if boss_ship == null:
		return

	var bh := boss_ship.get_node_or_null("BossHealth")
	if bh == null:
		return

	# Attach once
	_attach_to_boss(bh)


func _attach_to_boss(bh: Node) -> void:
	boss_health = bh
	_attached = true

	# Connect signals (use "if not is_connected" pattern if you re-use scene)
	if not boss_health.hp_changed.is_connected(_on_hp_changed):
		boss_health.hp_changed.connect(_on_hp_changed)
	if not boss_health.died.is_connected(_on_boss_died):
		boss_health.died.connect(_on_boss_died)

	visible = true

	# Immediately sync to current values
	_on_hp_changed(boss_health.hp, boss_health.max_hp)


func _on_hp_changed(hp: int, max_hp: int) -> void:
	max_value = max_hp
	value = hp
	visible = true


func _on_boss_died() -> void:
	visible = false
	_attached = false
	boss_health = null
