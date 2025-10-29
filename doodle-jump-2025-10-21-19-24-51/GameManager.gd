extends Node

signal caffeine_changed(value: float)        # 0.0 .. 1.0
signal can_switch_changed(can_switch: bool)
signal mode_changed(mode: int)               # 0 = DOODLE, 1 = COFFEE
signal died(reason: String)
signal reset_txt

const DOODLE_SCENE := "res://scenes/doodle_jump.tscn"
const COFFEE_SCENE := "res://scenes/coffee_mode.tscn"
const TITLE_SCENE :="res://scenes/titl_screen.tscn"

enum Mode { DOODLE, COFFEE }
var mode: Mode = Mode.DOODLE
var CAFFEINE : float = 0.5
var raison: String
var scoreId : String
var nomRempli : bool = false
var player_name : String
var sw_result: Dictionary
# --- Caféine et paramètres généraux ---
var caffeine: float = CAFFEINE
@export var doodle_rate: float = 0.2        # vitesse de montée en Doodle
@export var coffee_rate: float = -0.01       # vitesse de descente en Coffee
@export var allow_coffee_to_doodle_anytime: bool = false
var retry: bool = false
var block_input : bool = false

# --- État du jeu ---
var game_started: bool = false
var highscore: int = 0
var score_coffee: float = 0
var score_sugar: float = 0.0

func _ready() -> void:
	
	SilentWolf.configure({
	"api_key": "a6FXfUCJ022svQdpFj7vTWrqpJV89Mo2Qcrw9Li4",
	"game_id": "coffee_jump",
	"log_level": 1
  })

	SilentWolf.configure_scores({"open_scene_on_close": "res://scenes/MainPage.tscn"})
	set_process(true)
	emit_signal("mode_changed", mode)
	emit_signal("caffeine_changed", caffeine)
	emit_signal("can_switch_changed", _compute_can_switch())

func _process(delta: float) -> void:
	if not game_started:
		return

	# Met à jour la caféine
	if mode == Mode.DOODLE:
		_add_caffeine(doodle_rate * delta)
	else:
		_add_caffeine(coffee_rate * delta)

	# Mort naturelle par jauge
	if caffeine <= 0.0:
		_die("épuisé de caféine (Doodle)")
	elif caffeine >= 1.0:
		_die("overdose de caféine (Coffee)")

	emit_signal("can_switch_changed", _compute_can_switch())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and game_started:
		_on_space_pressed()

func start_game() -> void:
	game_started = true
	score_coffee = 0
	score_sugar = 0
	caffeine = CAFFEINE
	mode = Mode.DOODLE
	emit_signal("mode_changed", mode)
	emit_signal("caffeine_changed", caffeine)
	emit_signal("can_switch_changed", _compute_can_switch())

func _on_space_pressed() -> void:
	if _compute_can_switch():
		_toggle_mode()

func _toggle_mode() -> void:
	mode = Mode.COFFEE if mode == Mode.DOODLE else Mode.DOODLE
	emit_signal("mode_changed", mode)
	emit_signal("can_switch_changed", _compute_can_switch())

func _compute_can_switch() -> bool:
	return true # logique personnalisable selon gameplay

func _add_caffeine(amount: float) -> void:
	var prev = caffeine
	caffeine = clamp(caffeine + amount, 0.0, 1.0)
	if caffeine != prev:
		emit_signal("caffeine_changed", caffeine)

func _die(reason: String) -> void:
	if not game_started:
		return

	game_started = false

	# Calcul du score final
	var current_score: int = int(score_coffee - score_sugar)
	if current_score > highscore:
		highscore = current_score
		SilentWolf.Scores.save_score(player_name, highscore)
	raison=reason
	print("☠️ Mort : %s" % raison)
	print("Score : %d / Highscore : %d" % [current_score, highscore])
	GameOver.gameover()
	#emit_signal("over")
	emit_signal("died", reason)
	sw_result= await SilentWolf.Scores.get_scores().sw_get_scores_complete
	print("Scores: " + str(sw_result.scores))
	# Transition vers l’écran titre
	#get_tree().call_deferred("change_scene_to_file", TITLE_SCENE)
	

func reset_game_state() -> void:
	game_started = false
	retry = false
	block_input = false
	caffeine = CAFFEINE
	mode = Mode.DOODLE
	score_coffee = 0
	score_sugar = 0
	emit_signal("reset_txt")
	emit_signal("mode_changed", mode)
	emit_signal("caffeine_changed", caffeine)
	emit_signal("can_switch_changed", _compute_can_switch())
