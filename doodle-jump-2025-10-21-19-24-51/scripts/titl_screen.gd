extends Control

@onready var highscore := $main/highscore as Label# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	highscore.text = "Highscore\n"+str(GameManager.highscore)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void: # permet de lancer le jeu avec espace
	if event.is_action_pressed("start_game") and not GameManager.game_started:
		_on_startbtn_pressed()

func _on_quitbtn_pressed() -> void:
	get_tree().quit()
	
func _on_startbtn_pressed():
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://main.tscn")
	GameManager.score_sugar=0
	GameManager.score_coffee = 0
