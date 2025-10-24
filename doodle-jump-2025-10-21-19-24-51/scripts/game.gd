extends Node2D

@onready var platform_container := $platform_container
@onready var platform := $platform_container/platform
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player := $platform_container/player as CharacterBody2D
@onready var score_label := $platform_container/camera/CanvasLayer/score as Label
@onready var camera := $platform_container/camera as Camera2D
@onready var cafe := $platform_cleaner as Area2D

var last_platform_is_cloud := false
var last_platform_is_enemy := false
var camera_start_position := 0.0

@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform.tscn"),
	preload("res://platforms/spring_platform.tscn"),
	preload("res://platforms/cloud.tscn"),
	preload("res://actors/enemy.tscn")
]


func _ready() -> void:
	randomize()
	camera_start_position = camera.position.y
	level_generator(100)
	score_update()

	# Connexion au signal global de mort (pour interface ou retour menu)
	GameManager.died.connect(_on_died)

	# Démarre la partie si pas encore en cours
	if not GameManager.game_started:
		GameManager.start_game()


func _physics_process(delta: float) -> void:
	if not GameManager.game_started:
		return

	# Suivi de la caméra
	if player.position.y < camera.position.y:
		camera.position.y = player.position.y
		cafe.position.y = min(cafe.position.y, player.position.y + 120)
		score_update()
	elif player.position.y > camera.position.y + 150:
		camera.position.y = player.position.y

	# Suppression des objets sous le café
	for child in platform_container.get_children():
		if child.is_in_group("platform") or child.is_in_group("enemies"):
			if child.global_position.y > cafe.global_position.y + 130:
				child.call_deferred("queue_free")
				level_generator(1)


# ---------------------------------------------------------------------
# GÉNÉRATION DE PLATEFORMES
# ---------------------------------------------------------------------
func level_generator(amount: int) -> void:
	const ENEMY_MIN_SCORE := 50
	var score := -GameManager.score_sugar

	var spacing_factor: float = lerp(1.0, 1.8, clamp(float(score) / 200.0, 0.0, 1.0))

	for i in range(amount):
		var enemy_weight := 0.0
		if score >= ENEMY_MIN_SCORE:
			var raw : float = clamp((float(score) - ENEMY_MIN_SCORE) / 200.0, 0.0, 1.0)
			var t : float = raw * raw * raw
			enemy_weight = 0.10 + 0.30 * t

		var cloud_weight := 0.15
		var spring_weight := 0.25
		var normal_weight := 1.0 - (enemy_weight + cloud_weight + spring_weight)
		normal_weight = max(normal_weight, 0.05)

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

		if score < ENEMY_MIN_SCORE and new_type == 3:
			new_type = 0

		platform_initial_position_y -= randf_range(36.0, 54.0) * spacing_factor
		var new_platform: Node2D = null

		match new_type:
			0:
				new_platform = platform_scene[0].instantiate()
				last_platform_is_cloud = false
				last_platform_is_enemy = false
			1:
				new_platform = platform_scene[1].instantiate()
				last_platform_is_cloud = false
				last_platform_is_enemy = false
			2, 3:
				if not last_platform_is_cloud and not last_platform_is_enemy:
					new_platform = platform_scene[new_type].instantiate()
					if new_type == 2:
						last_platform_is_cloud = true
						last_platform_is_enemy = false
					else:
						last_platform_is_enemy = true
						last_platform_is_cloud = false
						var top_y := player.position.y - 300
						new_platform.position = Vector2(randf_range(20.0, 160.0), top_y)
						var support_platform := platform_scene[0].instantiate()
						support_platform.position = Vector2(randf_range(20.0, 160.0), platform_initial_position_y)
						if support_platform.has_signal("delete_object"):
							support_platform.connect("delete_object", self.delete_object)
						platform_container.call_deferred("add_child", support_platform)

					if new_platform.has_signal("delete_object"):
						new_platform.connect("delete_object", self.delete_object)
				else:
					new_platform = platform_scene[0].instantiate()
					last_platform_is_cloud = false
					last_platform_is_enemy = false

		if new_platform == null:
			push_error("level_generator: new_platform est null (type=%d)" % new_type)
			continue

		if new_type != 3:
			new_platform.position = Vector2(randf_range(20.0, 160.0), platform_initial_position_y)

		platform_container.call_deferred("add_child", new_platform)


# ---------------------------------------------------------------------
# GESTION DES COLLISIONS ET SUPPRESSIONS
# ---------------------------------------------------------------------
func delete_object(obstacle: Node) -> void:
	if obstacle.is_in_group("player"):
		GameManager._die("tombé dans le café (Doodle)")
	elif obstacle.is_in_group("platform") or obstacle.is_in_group("enemies"):
		obstacle.call_deferred("queue_free")
		level_generator(1)

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
	# Optionnel : effets de mort ou sons locaux
	print("Mort détectée dans Doodle Mode : %s" % reason)
