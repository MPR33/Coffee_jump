extends Area2D

@export var rise_speed := 600.0   # pixels/sec vers le haut

func _physics_process(delta):
	position.y += rise_speed * delta
