extends "res://scripts/platform.gd"
func response():
	$spring.play("default")


func _on_animated_sprite_2d_animation_finished() -> void:
	$spring.frame =0
	$spring.stop()
