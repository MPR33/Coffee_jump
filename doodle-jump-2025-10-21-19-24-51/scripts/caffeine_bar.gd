extends TextureProgressBar

@onready var warnings := $Warnings
@onready var halo := $Halo

const LOW  := 20.0
const HIGH := 80.0
enum Mode { DOODLE, COFFEE }
var _blink_tween: Tween

func _ready() -> void:
	# Démarrage propre
	warnings.visible = false
	warnings.modulate.a = 1.0
	halo.visible = false

	# Suivre la valeur de la barre
	value_changed.connect(_on_value_changed)
	_on_value_changed(value)  # maj initiale


func _on_value_changed(v: float) -> void:
	var critical := (v >= HIGH and GameManager.mode==Mode.DOODLE) or (v <= LOW and GameManager.mode==Mode.COFFEE)

	# Exclamations : visibles + clignotement fade si critique
	warnings.visible = critical
	if critical:
		_start_blink()
	else:
		_stop_blink()

	# Halo rouge : visible quand critique (tu peux aussi le faire pulser)
	halo.visible = critical
	if critical:
		# halo léger fade in (optionnel)
		var t := create_tween()
		t.tween_property(halo, "modulate:a", 1.0, 0.15).from(0.0)
	else:
		halo.modulate.a = 0.0


func _start_blink() -> void:
	if _blink_tween and _blink_tween.is_running():
		return
	_blink_tween = create_tween()
	_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink_tween.tween_property(warnings, "modulate:a", 0.25, 0.5) # vers 25% alpha
	_blink_tween.tween_property(warnings, "modulate:a", 1.00, 0.5) # retour plein
	_blink_tween.finished.connect(_restart_blink)


func _restart_blink() -> void:
	# Relance en boucle
	if warnings.visible:
		_start_blink()


func _stop_blink() -> void:
	if _blink_tween:
		_blink_tween.kill()
		_blink_tween = null
	warnings.modulate.a = 1.0
