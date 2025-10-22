extends CanvasLayer

@onready var bar: TextureProgressBar = $MarginContainer/CaffeineBar
@onready var label: Label = $MarginContainer/CaffeineBar/Label if has_node("MarginContainer/CaffeineBar/Label") else null

func _ready() -> void:
	# Config de base
	bar.min_value = 0
	bar.max_value = 100
	bar.value = GameManager.caffeine * 100.0

	# Connexions
	GameManager.caffeine_changed.connect(_on_caffeine_changed)
	GameManager.mode_changed.connect(_on_mode_changed)
	GameManager.can_switch_changed.connect(_on_can_switch_changed)
	GameManager.died.connect(_on_died)

	_on_mode_changed(GameManager.mode)
	_on_can_switch_changed(GameManager._compute_can_switch())

func _on_caffeine_changed(v: float) -> void:
	bar.value = v * 100.0
	if label:
		label.text = "%d%%" % int(round(v * 100.0))

func _on_mode_changed(mode: int) -> void:
	# optionnel : changer la couleur/titre selon le mode
	# ex: bar.tint_progress = (mode == GameManager.Mode.DOODLE) ? Color(0.8,0.9,1) : Color(1,0.9,0.6)
	pass

func _on_can_switch_changed(can_switch: bool) -> void:
	# optionnel : faire clignoter un contour, afficher "PRESS SPACE" quand on peut switch
	# ex: bar.modulate = can_switch ? Color(1,1,1) : Color(0.8,0.8,0.8)
	pass

func _on_died(_reason: String) -> void:
	# optionnel : flash rouge, bref feedback
	pass
