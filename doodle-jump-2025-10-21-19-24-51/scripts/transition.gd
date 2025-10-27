# Transition.gd — Godot 4.x
extends CanvasLayer

@onready var rect: ColorRect = get_node_or_null("ColorRect")

func _ready() -> void:
	# Toujours au-dessus et plein écran
	layer = 100
	visible = false

	# Si le ColorRect n'existe pas, on le crée.
	if rect == null:
		rect = ColorRect.new()
		rect.name = "ColorRect"
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(rect)
	else:
		# S'assure qu'il couvre l'écran si tu l'avais déjà
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Garantit un ShaderMaterial avec notre shader
	_ensure_shader_material()


func change_scene(path: String, center: Vector2 = Vector2.INF, duration := 0.6, feather := 8.0) -> void:
	var vp_size = get_viewport().get_visible_rect().size
	if center == Vector2.INF:
		center = vp_size * 0.5

	var mat := rect.material as ShaderMaterial
	var max_radius := vp_size.length()  # suffisant pour couvrir l'écran (≈ diagonale)

	# Paramètres initiaux : tout visible (gros trou)
	mat.set_shader_parameter("hole_center_px", center)
	mat.set_shader_parameter("feather", feather)
	mat.set_shader_parameter("radius", max_radius)

	visible = true

	# 1) Fermer vers noir
	await _tween_radius(mat, max_radius,0.0, duration)

	# 2) Changer de scène
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame  # laisse le temps de s'afficher

	# 3) Réouvrir
	await _tween_radius(mat, 0.0, max_radius, duration)

	visible = false


func _tween_radius(mat: ShaderMaterial, from: float, to: float, duration: float) -> void:
	mat.set_shader_parameter("radius", from)
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/radius", to, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _ensure_shader_material() -> void:
	var mat := rect.material
	if mat == null or not (mat is ShaderMaterial):
		mat = ShaderMaterial.new()
		mat.shader = load("res://iris.gdshader")  # adapte le chemin si besoin
		rect.material = mat
