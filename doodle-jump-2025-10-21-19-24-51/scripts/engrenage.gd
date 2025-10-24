extends Node2D

@export var speed: float = 60.0  # degrés par seconde
@export var direction: int = 1   # 1 ou -1

func _process(delta: float) -> void:
	rotation_degrees += speed * delta * direction
