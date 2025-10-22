extends Node

signal caffeine_changed(value: float)              # 0.0 .. 1.0
signal can_switch_changed(can_switch: bool)
signal mode_changed(mode: int)                     # 0 = DOODLE, 1 = COFFEE
signal died(reason: String)

const DOODLE_SCENE := "res://scenes/doodle_jump.tscn"
const COFFEE_SCENE := "res://scenes/coffee_mode.tscn"

enum Mode { DOODLE, COFFEE }
var mode: Mode = Mode.DOODLE

# --- Caféine & paramètres (tous éditables si tu veux @export) ---
var caffeine := 0.0                         # normalisée entre 0 et 1
@export var doodle_rate := 0.12             # /s, la vitesse à laquelle ça monte en Doodle
@export var coffee_rate := -0.10            # /s, la vitesse à laquelle ça descend en Coffee
@export var doodle_switch_threshold := 0.60  # au-dessus => on PEUT passer en Coffee
@export var coffee_min_threshold := 0.25     # en-dessous => on NE PEUT PAS quitter Coffee (et si trop bas => mort)
@export var allow_coffee_to_doodle_anytime := false  # si true, on peut sortir du Coffee quand on veut

var highscore := 0

func _ready() -> void:
	set_process(true)
	emit_signal("mode_changed", mode)
	emit_signal("caffeine_changed", caffeine)
	emit_signal("can_switch_changed", _compute_can_switch())

func _process(delta: float) -> void:
	# Met à jour la caféine selon le mode
	if mode == Mode.DOODLE:
		_add_caffeine(doodle_rate * delta)
	else:
		_add_caffeine(coffee_rate * delta)

	# Conditions de mort “naturelles” (optionnelles, adapte selon ton game design)
	if mode == Mode.COFFEE and caffeine <= 0.0:
		_die("épuisé de caféine (Coffee)")
	if mode == Mode.DOODLE and caffeine >= 1.0:
		_die("overdose de caféine (Doodle)")

	# Rafraîchir le statut de “peut changer ?”
	emit_signal("can_switch_changed", _compute_can_switch())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_space_pressed()

func _on_space_pressed() -> void:
	# Règle : on ne peut changer que si la jauge est du bon côté du seuil, sinon mort.
	if _compute_can_switch():
		_toggle_mode()
	else:
		# Si on appuie trop tôt/trop tard : mort
		_die("mauvais timing sur ESPACE")

func _toggle_mode() -> void:
	mode = Mode.COFFEE if mode == Mode.DOODLE else Mode.DOODLE

	emit_signal("mode_changed", mode)
	emit_signal("can_switch_changed", _compute_can_switch())

	var scene_path = DOODLE_SCENE if mode == Mode.DOODLE else COFFEE_SCENE

	var ok := get_tree().change_scene_to_file(scene_path)
	if ok != OK:
		push_warning("Impossible de changer de scène vers: %s" % scene_path)

func _compute_can_switch() -> bool:
	if mode == Mode.DOODLE:
		return caffeine >= doodle_switch_threshold
	# mode == COFFEE
	if allow_coffee_to_doodle_anytime:
		return true
	return caffeine > coffee_min_threshold

func _add_caffeine(amount: float) -> void:
	var prev := caffeine
	caffeine = clamp(caffeine + amount, 0.0, 1.0)
	if caffeine != prev:
		emit_signal("caffeine_changed", caffeine)

func _die(reason: String) -> void:
	emit_signal("died", reason)
	# À toi de décider ce qui se passe : retourner à l’écran titre, recharger la scène, etc.
	# Exemple :
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")
	# Ou bien laisse la scène courante écouter `GameManager.died` et gérer l'UI de Game Over.

func reset_game_state():
	caffeine = 0.0
	mode = Mode.DOODLE
	emit_signal("caffeine_changed", caffeine)
	emit_signal("mode_changed", mode)
	emit_signal("can_switch_changed", _compute_can_switch())
