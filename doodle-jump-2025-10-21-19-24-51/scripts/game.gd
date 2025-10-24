extends Node2D


@onready var platform_container := $platform_container
@onready var platform := $platform_container/platform
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player := $platform_container/player as CharacterBody2D
var last_platform_is_cloud:= false
var last_platform_is_enemy:=false
@onready var score_label :=$platform_container/camera/CanvasLayer/score as Label
@onready var camera_start_position =$platform_container/camera.position.y
@onready var camera :=$platform_container/camera as Camera2D
@onready var cafe :=$platform_cleaner as Area2D
@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform.tscn"),
	preload("res://platforms/spring_platform.tscn"),
	preload("res://platforms/cloud.tscn"),
	preload("res://actors/enemy.tscn")
]

func level_generator(amount: int) -> void:
	const ENEMY_MIN_SCORE := 50  # score minimal pour commencer à générer des ennemis
	var score := -GameManager.score_sugar

	# Facteur de difficulté : plus le score est élevé, plus l'espacement est grand (moins de plateformes)
	# Croît linéairement jusqu'à ~x1.8 à partir de 200 points
	var spacing_factor : float = lerp(1.0, 1.8, clamp(float(score) / 200.0, 0.0, 1.0))

	for i in range(amount):
		# --- Choix du type avec pondération dépendante du score ---
		# Avant ENEMY_MIN_SCORE : pas d'ennemi. Après : proba d'ennemi croissante.
		var enemy_weight := 0.0
		if score >= ENEMY_MIN_SCORE:
			var t : float = clamp((float(score) - float(ENEMY_MIN_SCORE)) / 200.0, 0.0, 1.0)
			enemy_weight = 0.10 + 0.30 * t  # de 10% à 40% d'ennemis

		var cloud_weight := 0.15          # nuages (2)
		var spring_weight := 0.25         # ressort (1)
		var normal_weight := 1.0 - (enemy_weight + cloud_weight + spring_weight) # normal (0)
		normal_weight = max(normal_weight, 0.05)  # garde un minimum de plateformes normales

		# Tirage pondéré
		var r := randf()
		var new_type := 0
		if r < normal_weight:
			new_type = 0
		elif r < normal_weight + spring_weight:
			new_type = 1
		elif r < normal_weight + spring_weight + cloud_weight:
			new_type = 2
		else:
			new_type = 3

		# Si le score est trop faible, on interdit les ennemis (sécurité supplémentaire)
		if score < ENEMY_MIN_SCORE and new_type == 3:
			new_type = 0

		# Espacement vertical (augmenté par la difficulté)
		platform_initial_position_y -= randf_range(36.0, 54.0) * spacing_factor

		var new_platform: Node2D = null

		if new_type == 0:
			# plate-forme normale
			new_platform = platform_scene[0].instantiate() as Node2D
			last_platform_is_cloud = false
			last_platform_is_enemy = false

		elif new_type == 1:
			# spring
			new_platform = platform_scene[1].instantiate() as Node2D
			last_platform_is_cloud = false
			last_platform_is_enemy = false

		else:
			# 2 = cloud, 3 = enemy
			# Empêcher deux spéciaux d’affilée
			if not last_platform_is_cloud and not last_platform_is_enemy:
				new_platform = platform_scene[new_type].instantiate() as Node2D
				if new_type == 2:
					last_platform_is_cloud = true
					last_platform_is_enemy = false
				else:
					# --- ENNEMI : apparaît en haut de l'écran + crée une plateforme 0 dédiée ---
					last_platform_is_enemy = true
					last_platform_is_cloud = false

					# Positionner l'ennemi en haut de l'écran (x random), légèrement hors-écran pour "entrer"
					var top_y := player.position.y-200
					new_platform.position = Vector2(randf_range(20.0, 160.0), top_y)

					# Générer une plateforme 0 au niveau courant (même "batch")
					var support_platform := platform_scene[0].instantiate() as Node2D
					support_platform.position = Vector2(randf_range(20.0, 160.0), platform_initial_position_y)
					if support_platform.has_signal("delete_object"):
						support_platform.connect("delete_object", self.delete_object)
					platform_container.call_deferred("add_child", support_platform)

				# Connecter un signal seulement s'il existe
				if new_platform != null and new_platform.has_signal("delete_object"):
					new_platform.connect("delete_object", self.delete_object)
			else:
				# fallback vers une plateforme simple
				new_platform = platform_scene[0].instantiate() as Node2D
				last_platform_is_cloud = false
				last_platform_is_enemy = false

		# Sécurité : si jamais null, on saute
		if new_platform == null:
			push_error("level_generator: new_platform est null (type=%d)" % new_type)
			continue

		# Pour les types non-ennemis, on place à la position habituelle.
		# (Pour l'ennemi, la position a déjà été mise tout en haut.)
		if new_type != 3:
			new_platform.position = Vector2(randf_range(20.0, 160.0), platform_initial_position_y)

		platform_container.call_deferred("add_child", new_platform)

<<<<<<< Updated upstream
=======

	
>>>>>>> Stashed changes
func _physics_process(delta : float) -> void:
	if player.position.y < camera.position.y:
		camera.position.y = player.position.y
		cafe.position.y = min(cafe.position.y, player.position.y + 80)
		score_update()
<<<<<<< Updated upstream
	if player.position.y > camera.position.y + 130:
=======
	if player.position.y > camera.position.y + 150:
>>>>>>> Stashed changes
		camera.position.y = player.position.y
	
	for child in platform_container.get_children():
		if child.is_in_group("platform") or child.is_in_group("enemies"):
			if child.global_position.y > cafe.global_position.y + 130 :
				child.queue_free()
				level_generator(1)

func delete_object(obstacle):
	if obstacle.is_in_group("player"):
		#get_tree().reload_current_scene()
		if GameManager.score_coffee-GameManager.score_sugar> GameManager.highscore:
			GameManager.highscore=GameManager.score_coffee-GameManager.score_sugar
		if get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")!=OK:
			print("je sais pas quoi mettre")
	elif obstacle.is_in_group("platform") or obstacle.is_in_group("enemies"):
		obstacle.queue_free()
		level_generator(1)
	
	
func _on_platform_cleaner_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		delete_object(body)

func score_update():
	GameManager.score_sugar = min(GameManager.score_sugar, player.position.y)
	score_label.text = str(int(-GameManager.score_sugar+GameManager.score_coffee))
	
func _on_died(reason: String) -> void:
	# Stoppe le jeu, affiche un panneau, enregistre highscore, etc.
	# Ou:
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")



func _ready() -> void:
	randomize()
	level_generator(100)
	GameManager.died.connect(_on_died)
	score_update()
