extends Node2D

@onready var platform_container: Node2D = $platform_container
@onready var platform: Node2D = $platform_container/platform
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player: CharacterBody2D = $platform_container/player
@onready var score_label: Label = $platform_container/camera/CanvasLayer/score
@onready var camera: Camera2D = $platform_container/camera
@onready var cafe: Area2D = $platform_cleaner

var last_platform_is_cloud: bool = false
var camera_start_position: float = 0.0

@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform.tscn"),
	preload("res://platforms/spring_platform.tscn"),
	preload("res://platforms/cloud.tscn")
]

@export var enemy_scene: PackedScene = preload("res://actors/enemy.tscn")

# Timer interne pour la génération d'ennemis
var enemy_timer: float = 0.0


# ---------------------------------------------------------------------
# INITIALISATION
# ---------------------------------------------------------------------
func _ready() -> void:
	randomize()
	camera_start_position = camera.position.y
	level_generator(10)
	score_update()

	GameManager.died.connect(_on_died)

	if not GameManager.game_started:
		GameManager.start_game()


# ---------------------------------------------------------------------
# MISE À JOUR PHYSIQUE
# ---------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not GameManager.game_started:
		return
	# Suivi caméra et score
	if player.position.y < camera.position.y:
		camera.position.y = player.position.y
		cafe.position.y = min(cafe.position.y, player.position.y + 120.0)
		score_update()
	elif player.position.y > camera.position.y + 150.0:
		camera.position.y = player.position.y

	# Suppression des objets sous le café
	for child: Node in platform_container.get_children():
		if child.is_in_group("platform") or child.is_in_group("enemies"):
			if child.global_position.y > cafe.global_position.y + 130.0:
				child.call_deferred("queue_free")
				level_generator(1)

	# Génération temporelle des ennemis
	enemy_spawner(delta)


# ---------------------------------------------------------------------
# GÉNÉRATION DE PLATEFORMES
# ---------------------------------------------------------------------
func level_generator(amount: int) -> void:
	var score: float = -GameManager.score_sugar
	var spacing_factor: float = lerp(0.6, 1.25, clamp(score / 9500.0, 0.0, 1.0))
	var delta_platform_initial_position_y = 0.0
	for i: int in range(amount):
		var cloud_weight: float = 0.15
		var spring_weight: float = 0.25
		var normal_weight: float = 1.0 - (cloud_weight + spring_weight)

		var r: float = randf()
		var new_type: int = 0
		if r < normal_weight:
			new_type = 0
		elif r < normal_weight + spring_weight:
			new_type = 1
		else:
			new_type = 2

		delta_platform_initial_position_y = randf_range(70, 100) * spacing_factor
		var new_platform: Node2D = platform_scene[new_type].instantiate() as Node2D
		
		if last_platform_is_cloud :
			platform_initial_position_y -= delta_platform_initial_position_y /2
		else:
			platform_initial_position_y -= delta_platform_initial_position_y
		
		new_platform.position = Vector2(randf_range(20.0, 160.0), platform_initial_position_y)
		last_platform_is_cloud = (new_type == 2)

		if new_platform.has_signal("delete_object"):
			new_platform.connect("delete_object", Callable(self, "delete_object"))

		platform_container.call_deferred("add_child", new_platform)


# ---------------------------------------------------------------------
# GÉNÉRATION RÉGULIÈRE DES ENNEMIS
# ---------------------------------------------------------------------
func enemy_spawner(delta: float) -> void:
	const ENEMY_MIN_SCORE: float = 500.0
	var score: float = -GameManager.score_sugar
	if score < ENEMY_MIN_SCORE:
		return

	# Le timer s’incrémente en continu
	enemy_timer += delta

	# Fréquence de vérification : toutes les 0.4–0.8 s selon la progression
	var base_interval: float = lerp(0.8, 0.3, clamp(score / 8000.0, 0.0, 1.0))

	if enemy_timer >= base_interval:
		enemy_timer = 0.0

		# Probabilité d’apparition qui croît avec le score
		var raw: float = clamp((score - ENEMY_MIN_SCORE) / 200.0, 0.0, 1.0)
		var t: float = raw * raw * raw
		var enemy_prob: float = 0.10 + 0.9 * t  # entre 5% et 30%

		if randf() < enemy_prob:
			spawn_enemy()


func spawn_enemy() -> void:
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	var top_y: float = player.position.y - 250.0
	enemy.position = Vector2(randf_range(20.0, 160.0), top_y)

	if enemy.has_signal("delete_object"):
		enemy.connect("delete_object", Callable(self, "delete_object"))

	platform_container.call_deferred("add_child", enemy)


# ---------------------------------------------------------------------
# GESTION DES COLLISIONS ET SUPPRESSIONS
# ---------------------------------------------------------------------
func delete_object(obstacle: Node) -> void:
	if obstacle.is_in_group("player"):
		GameManager._die("tombé dans le café ")
	elif obstacle.is_in_group("platform"):
		obstacle.call_deferred("queue_free")
		level_generator(1)
	elif obstacle.is_in_group("enemies"):
		obstacle.call_deferred("queue_free")


func _on_platform_cleaner_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		call_deferred("delete_object", body)


# ---------------------------------------------------------------------
# SCORE
# ---------------------------------------------------------------------
func score_update() -> void:
	GameManager.score_sugar = min(GameManager.score_sugar, player.position.y)
	score_label.text = str(int(-GameManager.score_sugar + GameManager.score_coffee))


# ---------------------------------------------------------------------
# ÉVÉNEMENTS
# ---------------------------------------------------------------------
func _on_died(reason: String) -> void:
	print("Mort détectée dans Doodle Mode : %s" % reason)
