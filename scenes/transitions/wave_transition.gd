extends CanvasLayer

@onready var screen_copy: TextureRect = $ScreenCopy
@onready var fade_rect: ColorRect = $FadeRect
@onready var shader_mat: ShaderMaterial = screen_copy.material

@export var duration: float = 1.6  # total time for full transition

var _time: float = 0.0

func _ready() -> void:
	# Lock player & furl sails while transitioning
	get_tree().call_group("player", "lock_for_transition")

	# Start fully visible screenshot, no black yet
	screen_copy.modulate.a = 1.0
	fade_rect.modulate.a = 0.0

func set_screenshot(tex: Texture2D) -> void:
	screen_copy.texture = tex

func _process(delta: float) -> void:
	_time += delta
	var t: float = clampf(_time / duration, 0.0, 1.0)

	# Waves strongest at start, calm down toward end
	shader_mat.set_shader_parameter("progress", t)

	# --- PHASES ---
	# 0.0 - 0.5  : screenshot + wave, fade to black
	# 0.5 - 1.0  : fully black, then fade black out to reveal town

	if t < 0.5:
		# Fade in black over the screenshot
		var k := t / 0.5  # 0→1
		fade_rect.modulate.a = k
		screen_copy.modulate.a = 1.0
	else:
		# After midpoint, screenshot is gone; town is behind black
		screen_copy.modulate.a = 0.0

		# Fade black back out to reveal the town scene
		var k := (t - 0.5) / 0.5  # 0→1 over second half
		fade_rect.modulate.a = 1.0 - k

	if t >= 1.0:
		get_tree().call_group("player", "unlock_after_transition")
		queue_free()
