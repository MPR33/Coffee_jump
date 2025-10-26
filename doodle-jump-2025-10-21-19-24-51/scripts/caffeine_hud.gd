extends CanvasLayer

const LOW_THRESH  := 0.15
const HIGH_THRESH := 0.80 

@onready var bar: TextureProgressBar = $MarginContainer/CaffeineBar
@onready var label: Label = get_node_or_null("MarginContainer/CaffeineBar/Label")

var _blink_tween: Tween = null
var _is_blinking: bool = false

func _ready() -> void:
	# Config de base
	bar.min_value = 0
	bar.max_value = 100
	bar.value = GameManager.caffeine * 100.0
	_reset_visuals()

	# Connexions
	GameManager.caffeine_changed.connect(_on_caffeine_changed)
	GameManager.mode_changed.connect(_on_mode_changed)
	GameManager.can_switch_changed.connect(_on_can_switch_changed)
	GameManager.died.connect(_on_died)

	_on_mode_changed(GameManager.mode)
	_on_can_switch_changed(GameManager._compute_can_switch())
	_update_blinking()  # état initial

func _on_caffeine_changed(v: float) -> void:
	bar.value = v * 100.0
	if label:
		label.text = "%d%%" % int(round(v * 100.0))
	_update_blinking()

func _on_mode_changed(mode: int) -> void:
	# (optionnel) adapter la couleur selon le mode
	# bar.tint_progress = (mode == GameManager.Mode.DOODLE) ? Color(0.8,0.9,1) : Color(1,0.9,0.6)
	_update_blinking()

func _on_can_switch_changed(_can_switch: bool) -> void:
	# rien à faire pour le clignotement ici
	pass

func _on_died(_reason: String) -> void:
	_stop_blinking()
	# (optionnel) flash rouge / feedback

# ---------------------
#      BLINK LOGIC
# ---------------------

func _should_blink() -> bool:
	var v := GameManager.caffeine  # 0..1
	var m := GameManager.mode
	if m == GameManager.Mode.DOODLE:
		return v < LOW_THRESH
	elif m == GameManager.Mode.COFFEE:
		return v > HIGH_THRESH
	return false

func _update_blinking() -> void:
	var want := _should_blink()
	if want and not _is_blinking:
		_start_blinking()
	elif (not want) and _is_blinking:
		_stop_blinking()

func _start_blinking() -> void:
	_is_blinking = true
	# Nettoie un tween existant si besoin
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = create_tween()
	_blink_tween.set_loops()  # infini
	_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# On fait pulser l’alpha entre 1.0 et 0.35 en 0.45s (aller) puis retour 0.45s
	# (un seul tween enchaîné ping-pong)
	_blink_tween.tween_property(bar, "modulate:a", 0.35, 0.20)
	if label:
		_blink_tween.parallel().tween_property(label, "modulate:a", 0.35, 0.20)
	# Retour à 1.0
	_blink_tween.tween_property(bar, "modulate:a", 1.0, 0.20)
	if label:
		_blink_tween.parallel().tween_property(label, "modulate:a", 1.0, 0.20)

func _stop_blinking() -> void:
	_is_blinking = false
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = null
	_reset_visuals()

func _reset_visuals() -> void:
	bar.modulate = Color(1,1,1,1)
	if label:
		label.modulate = Color(1,1,1,1)
