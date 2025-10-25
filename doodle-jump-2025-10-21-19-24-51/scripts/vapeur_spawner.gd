extends Node2D
@export var vapeur=preload("res://actors/vapeur.tscn")

func _on_timer_timeout() -> void:
	var enemy=vapeur.instantiate()
	add_child(enemy)
	enemy.position.y=50
