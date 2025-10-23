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
@onready var cafe :=$platform_container/camera/platform_cleaner as Area2D
@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform.tscn"),
	preload("res://platforms/spring_platform.tscn"),
	preload("res://platforms/cloud.tscn"),
	preload("res://actors/enemy.tscn")
]




func level_generator(amount: int) -> void:
	for i in range(amount):
		var new_type := randi() % platform_scene.size()  # 0..3
		platform_initial_position_y -= randf_range(36.0, 54.0)

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
			# 2 = cloud, 3 = enemy (par ex.)
			# Empêcher deux spéciaux d’affilée
			if not last_platform_is_cloud and not last_platform_is_enemy:
				new_platform = platform_scene[new_type].instantiate() as Node2D
				if new_type == 2:
					last_platform_is_cloud = true
					last_platform_is_enemy = false
				else:
					last_platform_is_enemy = true
					last_platform_is_cloud = false
				# Connecter un signal seulement s'il existe
				if new_platform.has_signal("delete_object"):
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

		new_platform.position = Vector2(randf_range(20.0, 160.0), platform_initial_position_y)
		platform_container.call_deferred("add_child", new_platform)

		


	
func _physics_process(delta : float) -> void:
	if player.position.y < camera.position.y:
		camera.position.y = player.position.y 
		score_update()

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
	level_generator(200)
	GameManager.died.connect(_on_died)
	score_update()
