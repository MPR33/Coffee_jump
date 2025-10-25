extends Control

@export var duration: float = 3.0
@export var jitter_amplitude: float = 6.0
@export var jitter_interval: float = 0.05
@export var bottom_padding: float = 50.0

@onready var icon := $TextureRect as TextureRect

var _x_screen: float = 0.0
var _base_pos: Vector2
var _accum: float = 0.0

func setup(x: float, seconds: float = -1.0) -> void:
	_x_screen = x
	if seconds > 0.0:
		duration = seconds

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame

	# Centrer visuellement sur l’icône si dispo
	var tex_size := Vector2.ZERO
	if icon.texture:
		tex_size = icon.texture.get_size()
	if tex_size != Vector2.ZERO:
		size = tex_size
		pivot_offset = size * 0.5
		icon.set_anchors_preset(Control.PRESET_CENTER)

	# Bas de l’écran (coords UI)
	var view_size := get_viewport().get_visible_rect().size
	var y := view_size.y - bottom_padding
	_base_pos = Vector2(_x_screen, y)
	position = _base_pos

	# Auto-destruction
	get_tree().create_timer(duration).timeout.connect(queue_free)

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= jitter_interval:
		_accum = 0.0
		var off := Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0)
		if off.length() > 0.0:
			off = off.normalized() * jitter_amplitude
		else:
			off = Vector2.ZERO
		position = _base_pos + off
