extends "res://scripts/platform.gd"
func response():
	emit_signal("delete_object",self)
