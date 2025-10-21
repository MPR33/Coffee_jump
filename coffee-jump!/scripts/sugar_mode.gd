extends Node2D

@export var platform_scene : PackedScene = preload("res://scenes/platform.tscn")
@export var num_initial_platforms : int = 5
@export var vertical_gap : int = 120
@export var horizontal_range : int = 300
@export var player_node_path : NodePath
@export var coffee_speed : float = 30.0        # vitesse de montée en pixels/seconde
@export var coffee_min_distance : float = 300.0 # distance max entre joueur et café
@export var coffee_color_node : NodePath = NodePath("CoffeeLine/CoffeeVisual")
@export var coffee_area_node : NodePath = NodePath("CoffeeLine/CoffeeKillZone")


var platforms : Array = []
var player : Node2D = null

func _ready():
	if player_node_path != NodePath(""):
		player = get_node(player_node_path)
	else:
		push_error("Aucun joueur assigné à player_node_path !")
		return

	var y = 0
	for i in range(num_initial_platforms):
		spawn_platform(Vector2(randf_range(-horizontal_range, horizontal_range), y))
		y -= vertical_gap
	
	# Référence du café
	var coffee_area = get_node(coffee_area_node)
	if coffee_area:
		coffee_area.body_entered.connect(_on_coffee_body_entered)

func _on_coffee_body_entered(body: Node) -> void:
	if body == player:
		print("Le joueur est tombé dans le café ☕💀")
		get_tree().reload_current_scene()

func _physics_process(_delta):
	if not player:
		return

	# Génération de nouvelles plateformes si le joueur monte
	var highest_platform_y = get_highest_platform_y()
	if player.global_position.y < highest_platform_y + 300:
		spawn_platform(Vector2(randf_range(-horizontal_range, horizontal_range), highest_platform_y - vertical_gap))

	# --- Gestion du niveau de café ---
	var coffee_line := get_node_or_null(coffee_color_node)
	var coffee_area := get_node_or_null(coffee_area_node)
	if not coffee_line or not coffee_area:
		return

	# Récupère la hauteur du café (visuel)
	var coffee_visual := coffee_line.get_node_or_null("CoffeeVisual")
	var coffee_height: float = 200.0
	if coffee_visual and coffee_visual.has_variable("size"):
		coffee_height = coffee_visual.size.y

	# --- Montée naturelle (jamais descendante) ---
	var new_y: float = coffee_line.global_position.y - coffee_speed * _delta

	# --- Rattrapage si le café est trop bas par rapport à la caméra ---
	var camera_node := player.get_node_or_null("Camera2D")
	var camera_y: float = camera_node.global_position.y if camera_node else player.global_position.y
	var coffee_surface_y: float = new_y - coffee_height / 2.0
	var max_allowed_gap: float = 300.0  # distance max entre la caméra et le haut du café

	if (-camera_y + coffee_surface_y) > max_allowed_gap:
		# repositionne le café juste sous la caméra
		coffee_surface_y = camera_y + max_allowed_gap
		new_y = coffee_surface_y + coffee_height / 2.0

	# Empêche le café de redescendre (jamais)
	if coffee_line.global_position.y < new_y:
		new_y = coffee_line.global_position.y

	# Mise à jour positions globales
	coffee_line.global_position.y = new_y
	coffee_area.global_position.y = new_y

	# --- Suppression des plateformes submergées (pile à la surface) ---
	var surface_y: float = coffee_line.global_position.y
	for p in platforms.duplicate():
		if p.global_position.y > surface_y:
			p.queue_free()
			platforms.erase(p)

func spawn_platform(pos : Vector2):
	var p = platform_scene.instantiate()
	add_child(p)
	p.global_position = pos
	platforms.append(p)

func get_highest_platform_y() -> float:
	var highest = 0
	for p in platforms:
		if p.global_position.y < highest:
			highest = p.global_position.y
	return highest
