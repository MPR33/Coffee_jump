extends Control

@export var duration: float = 3.0          # durée d'affichage
@export var jitter_amplitude: float = 6.0  # px
@export var jitter_interval: float = 0.05  # s

@onready var icon := $TextureRect as TextureRect

var target_world_pos: Vector2
var _base_screen_pos: Vector2
var _accum := 0.0

func setup(world_pos: Vector2, seconds: float = -1.0) -> void:
	target_world_pos = world_pos
	if seconds > 0.0:
		duration = seconds

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Centre le Control sur l'icône
	await get_tree().process_frame
	var tex_size := Vector2.ZERO
	if icon.texture:
		tex_size = icon.texture.get_size()
	if tex_size != Vector2.ZERO:
		size = tex_size
		pivot_offset = size * 0.5
		icon.anchors_preset = Control.PRESET_CENTER
	# Auto-destruction
	get_tree().create_timer(duration).timeout.connect(queue_free)

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	# Monde -> écran
	_base_screen_pos = cam.get_screen_transform() * target_world_pos
	# Jitter autour de la position écran
	_accum += delta
	if _accum >= jitter_interval:
		_accum = 0.0
		var off := Vector2(randf()*2.0-1.0, randf()*2.0-1.0).normalized() * jitter_amplitude
		global_position = _base_screen_pos + off
