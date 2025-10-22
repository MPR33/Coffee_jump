extends Node

const DOODLE_SCENE := "res://scenes/doodle_jump.tscn"
const COFFEE_SCENE := "res://scenes/coffee_mode.tscn"
var highscore:=0
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Espace mappé sur ui_accept
		toggle_mode()

func toggle_mode() -> void:

	var cur := get_tree().current_scene
	if cur and cur.scene_file_path == DOODLE_SCENE:
		get_tree().change_scene_to_file(COFFEE_SCENE)
	else:
		get_tree().change_scene_to_file(DOODLE_SCENE)
	get_tree().paused = true

	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false   # ✅ gèle le jeu instantanément

func _change_to(path: String) -> void:
	# (facultatif) ajoute une petite transition ici si tu veux
	get_tree().change_scene_to_file(path)
