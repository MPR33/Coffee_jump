extends TextureRect # ou Sprite2D en fonction

@onready var spectrum := AudioServer.get_bus_effect_instance(
	AudioServer.get_bus_index("Master"),  # ton bus audio
	0                                      # index de l’effet Spectrum Analyzer
)
func _ready() -> void:
	set_process(true)
func _process(delta):
	print("process ok")
	if spectrum == null:
		print("nul")
		return

	# énergie des basses (GO : 40-150 Hz)
	var energy = spectrum.get_magnitude_for_frequency_range(40, 150).length()

	# on convertit cette énergie en scale (exemple : base 1.0 → max 1.3)
	var scale_value = 1.0 + energy * 4.0  # ajuste le *4 si trop violent
	scale = Vector2(scale_value, scale_value)
	print("scale")
