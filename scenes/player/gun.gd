extends Node2D

@export var cannonball_scene: PackedScene
@export var smoke_scene: PackedScene
@export var shoot_speed: float = 375.0

var cannon_sounds: Array[String] = [
	"res://assets/sfx/Cannon/cannon_1.mp3",
	"res://assets/sfx/Cannon/cannon_2.mp3",
	"res://assets/sfx/Cannon/cannon_3.mp3",
	"res://assets/sfx/Cannon/cannon_4.mp3",
	"res://assets/sfx/Cannon/cannon_5.mp3",
	"res://assets/sfx/Cannon/cannon_6.mp3",
]

@onready var gun_sprite: AnimatedSprite2D = $GunSprite
@onready var boom: AudioStreamPlayer2D = $Boom
@onready var muzzle: Marker2D = $Muzzle

func fire() -> void:
	gun_sprite.play()

	var path: String = cannon_sounds.pick_random()
	boom.stream = load(path) as AudioStream
	boom.play()

	# Smoke at muzzle (auto-free when animation ends)
	if smoke_scene:
		var smoke := smoke_scene.instantiate() as Node2D
		if smoke:
			smoke.global_position = muzzle.global_position
			smoke.global_rotation = muzzle.global_rotation
			get_tree().current_scene.add_child(smoke)

		# Create a timer that removes the smoke after X seconds
		var t := Timer.new()
		t.wait_time = 0.6
		t.one_shot = true
		smoke.add_child(t)
		t.start()
		t.timeout.connect(func(): smoke.queue_free())

	# small firing delay
	await get_tree().create_timer(0.2).timeout

	# Spawn cannonball (typed)
	if cannonball_scene:
		var ball: = cannonball_scene.instantiate()
		ball.global_position = muzzle.global_position
		ball.global_rotation = muzzle.global_rotation
		ball.speed = shoot_speed
		get_tree().current_scene.add_child(ball)
