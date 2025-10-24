extends Node2D

@onready var platform_container := $platform_container_coffee
@onready var platform := $platform_container_coffee/platform_coffee
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player := $platform_container_coffee/coffee_bean as CharacterBody2D
var last_platform_is_cloud:= false
@onready var score_label :=$platform_container_coffee/camera/CanvasLayer/score as Label
@onready var camera_start_position =$platform_container_coffee/camera.position.y
@onready var camera :=$platform_container_coffee/camera as Camera2D
@onready var cafe :=$platform_cleaner_coffee as Area2D
@onready var cafe2 :=$platform_cleaner_coffee2 as Area2D
@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform.tscn"),
	preload("res://platforms/platform_coffee.tscn")
]

func level_generator(amount):
	for items in amount :
		var new_type = randi()%2
		#0 1
		var new_platform 
		
		if new_type==0:
			platform_initial_position_y += randf_range(36,54)
			new_platform= platform_scene[0].instantiate() as StaticBody2D
			new_platform.position = Vector2(randf_range(15,170), platform_initial_position_y)
			platform_container.call_deferred('add_child', new_platform)
		if new_type==1:
			platform_initial_position_y += randf_range(36,54)
			new_platform= platform_scene[1].instantiate() as StaticBody2D
			new_platform.position = Vector2(randf_range(20,165), platform_initial_position_y)
			platform_container.call_deferred('add_child', new_platform)
		

func _ready() -> void:
	randomize()
	level_generator(100)
	GameManager.died.connect(_on_died)
	score_update()
	
func _physics_process(delta : float) -> void:
	if player.position.y > camera.position.y:
		camera.position.y = player.position.y
		score_update()
	if player.position.y < camera.position.y - 130:
		camera.position.y = player.position.y
	
	for child in platform_container.get_children():
		if child.is_in_group("platform") or child.is_in_group("enemies"):
			if child.global_position.y < cafe.global_position.y - 200 :
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
	
	
func _on_platform_cleaner_coffee_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		delete_object(body)

func _on_platform_cleaner_coffee_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		delete_object(body)

func score_update():
	GameManager.score_coffee=max(player.position.y,GameManager.score_coffee)
	score_label.text = str(int(GameManager.score_coffee-GameManager.score_sugar))
	
func _on_died(reason: String) -> void:
	# Stoppe le jeu, affiche un panneau, enregistre highscore, etc.
	# Ou:
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")
