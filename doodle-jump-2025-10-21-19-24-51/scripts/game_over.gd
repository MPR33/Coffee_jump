extends CanvasLayer
@onready var son :=$MusicIntro
@onready var leaderboard := $Panel2
@onready var gameoverscreen:=$Panel
# Called when the node enters the scene tree for the first time.
func _ready():
	self.hide()
	$MusicIntro.play()
	$MusicIntro.finished.connect(on_intro_finished)
	$LabelMort.start_typing.connect($TypingSfx.play)
	$LabelMort.stop_all.connect(_stop_everything)
	#$TypingSfx.finished.connect(_on_typing_sfx_finished) # optionnel
	#GameManager.over.connect(gameover)

func on_intro_finished():
	$LabelMort.start_typing_text()

func _stop_everything():
	$MusicIntro.stop()
	$TypingSfx.stop()


func gameover()-> void:
	self.show()
	son.play()
	get_tree().paused=true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void: # permet de lancer le jeu avec espace
	if event.is_action_pressed("start_game") and not GameManager.game_started:
		_on_retry_pressed()

func _on_retry_pressed() -> void:
	_stop_everything()
	hide()
	get_tree().paused=false
	GameManager.retry = true
	call_deferred("_go_title")
	
func _go_title() -> void:
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")


func _on_boutonleader_pressed() -> void:
	leaderboard.visible=true
	gameoverscreen.visible=false
	leaderboard._populate_leaderboard()
