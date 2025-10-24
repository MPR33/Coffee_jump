extends Node2D
@onready var shaker := $shaker as Node2D

@export var amplitude := 4.0   # tremblement max en pixels (2 à 6 conseillé)
@export var speed := 15.0      # vitesse du jitter (10 à 20)

var _time := 0.0

func _process(delta):
	_time += delta * speed
	# petit déplacement aléatoire mais lissé (sinus + random léger)
	var offset = Vector2(
		sin(_time * 1.3 + randf() * 10.0),
		sin(_time * 1.7 + randf() * 10.0)
	) * amplitude
	shaker.position = offset
