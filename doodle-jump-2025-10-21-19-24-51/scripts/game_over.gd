extends CanvasLayer
@onready var son :=$MusicIntro
@onready var leaderboard := $Panel2
@onready var gameoverscreen:=$Panel
@onready var add_score_http: HTTPRequest = $GameOverhttp
@onready var get_score_http: HTTPRequest = $Panel2/leaderboardhttp

var can_retry : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	self.hide()
	can_retry = false
	$MusicIntro.play()
	$MusicIntro.finished.connect(on_intro_finished)
	$LabelMort.start_typing.connect($TypingSfx.play)
	$LabelMort.stop_all.connect(_stop_everything)
	assert(add_score_http, "Chemin vers GameOver/GameOverhttp invalide")
	assert(get_score_http, "Chemin vers GameOver/Panel2/leaderboardhttp invalide")
	
	#$TypingSfx.finished.connect(_on_typing_sfx_finished) # optionnel
	#GameManager.over.connect(gameover)

func on_intro_finished():
	can_retry = true
	$LabelMort.start_typing_text()

func _stop_everything():
	$MusicIntro.stop()
	$TypingSfx.stop()


func upload_score(player_name: String, score: int) -> void:
	var headers = ["Content-Type: application/json"]
	var body = {"player": player_name, "score": score}
	add_score_http.request(
		"https://coffee.maoune.fr/score/add/",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

func get_scores() -> void:
	get_score_http.request("https://coffee.maoune.fr/score/list")

func gameover()-> void:
	self.show()
	son.play()
	get_tree().paused=true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void: # permet de lancer le jeu avec enter
	if event.is_action_pressed("start_game") and not GameManager.game_started and can_retry:
		_on_retry_pressed()

func _on_retry_pressed() -> void:
	_stop_everything()
	hide()
	GameManager.retry = true
	can_retry = false
	get_tree().paused=false
	call_deferred("_go_title")
	
func _go_title() -> void:
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")


func _on_boutonleader_pressed() -> void:
	get_scores()
	leaderboard.visible=true
	gameoverscreen.visible=false


func _on_game_overhttp_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Réponse serveur add score:", response_code, body.get_string_from_utf8())
