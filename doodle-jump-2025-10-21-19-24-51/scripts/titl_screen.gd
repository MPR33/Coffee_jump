extends Control

@onready var highscore := $main/highscore as Label# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	highscore.text = "Highscore\n"+str(GameManager.highscore)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_startbtn_pressed() -> void:
	if get_tree().change_scene_to_file("res://scenes/doodle_jump.tscn")!=OK:
		print("je sais pas quoi mettre")

func _on_quitbtn_pressed() -> void:
	get_tree().quit()
