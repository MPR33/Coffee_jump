extends "res://scripts/platform.gd"
func response():
	emit_signal("delete_object",self)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
