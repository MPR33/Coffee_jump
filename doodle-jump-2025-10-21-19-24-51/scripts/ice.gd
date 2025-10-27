extends StaticBody2D

@export var jumpforce := 1.0
signal delete_object(obstacle)

func _ready():
	add_to_group("ice")
