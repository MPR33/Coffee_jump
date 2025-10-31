extends TextureProgressBar

@onready var warnings := $Warnings
@onready var halo := $Halo

const LOW  := 10.0   # v en 0..100
const HIGH := 90.0

var _blink_tween: Tween

func _ready() -> void:
	# Démarrage propre
	warnings.visible = false
	warnings.modulate.a = 1.0
	halo.visible = false
	halo.modulate.a = 0.0

	# Suivre la valeur de la barre
	value_changed.connect(_on_value_changed)
	_on_value_changed(value)  # maj initiale

	# IMPORTANT : suivre aussi le changement de mode
	GameManager.mode_changed.connect(_on_mode_changed)

func _on_mode_changed(_mode: int) -> void:
	# Couper immédiatement tout clignotement de l'ancien mode
	_stop_blink()
	# Recalcule l'état critique dans le nouveau mode
	_apply_state(value)

func _on_value_changed(v: float) -> void:
	_apply_state(v)

func _apply_state(v: float) -> void:
	var critical := _is_critical(v, GameManager.mode)

	# Exclamations
	warnings.visible = critical
	if critical:
		_start_blink()
	else:
		_stop_blink()

	# Halo rouge
	halo.visible = critical
	if critical:
		var t := create_tween()
		t.tween_property(halo, "modulate:a", 1.0, 0.15).from(0.0)
	else:
		halo.modulate.a = 0.0

func _is_critical(v: float, mode: int) -> bool:
	# Cohérent avec le HUD :
	# DOODLE => blink si TROP BAS ; COFFEE => blink si TROP HAUT
	if mode == GameManager.Mode.DOODLE:
		return v <= LOW
	elif mode == GameManager.Mode.COFFEE:
		return v >= HIGH
	return false

func _start_blink() -> void:
	if _blink_tween and _blink_tween.is_valid() and _blink_tween.is_running():
		return
	_blink_tween = create_tween()
	_blink_tween.set_loops()
	_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink_tween.tween_property(warnings, "modulate:a", 0.25, 0.5)
	_blink_tween.tween_property(warnings, "modulate:a", 1.00, 0.5)

func _stop_blink() -> void:
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = null
	warnings.modulate.a = 1.0
