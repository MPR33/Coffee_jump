extends TextureProgressBar

@onready var warnings := $Warnings
@onready var halo := $Halo

const LOW  := 10.0   # v en 0..100
const HIGH := 90.0

var _blink_tween: Tween
var _has_received_value := false     # on a reçu une vraie valeur ?
var _allow_display := false          # autorisation d’afficher warnings/halo ?

func _ready() -> void:
	# Démarrage propre
	warnings.visible = false
	warnings.modulate.a = 0.0
	halo.visible = false
	halo.modulate.a = 0.0
	_allow_display = false

	# On NE PASSE PAS value ici tout de suite (évite le flash)
	value_changed.connect(_on_value_changed)

	# Suivre le mode
	GameManager.mode_changed.connect(_on_mode_changed)

	# On autorise l’affichage après 1 frame (quand tout est branché)
	_defer_enable_display()

func _on_value_changed(v: float) -> void:
	_has_received_value = true
	_recompute(v)

func _on_mode_changed(_mode: int) -> void:
	# On coupe immédiatement et on masque pendant une frame
	_stop_blink()
	_force_hidden()
	_allow_display = false
	# Laisse Godot propager la nouvelle valeur/mode avant d’afficher
	_defer_enable_display()

func _defer_enable_display() -> void:
	await get_tree().process_frame
	_allow_display = true
	if _has_received_value:
		_recompute(value)

func _recompute(v: float) -> void:
	# Tant que l’affichage n’est pas autorisé, on reste caché
	if not _allow_display:
		_force_hidden()
		return

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
	# Restaure état plein (mais on gère la visibilité ailleurs)
	warnings.modulate.a = 1.0

func _force_hidden() -> void:
	# Utilisé pendant la frame de grâce
	warnings.visible = false
	warnings.modulate.a = 0.0
	halo.visible = false
	halo.modulate.a = 0.0
