extends Node2D

@onready var platform_container := $platform_container
@onready var platform := $platform_container/platform_coffee
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player := $platform_container/coffee_bean as CharacterBody2D
var last_platform_is_cloud:= false
@onready var score_label :=$platform_container/camera/CanvasLayer/score as Label
@onready var camera_start_position =$platform_container/camera.position.y
@onready var camera :=$platform_container/camera as Camera2D
@onready var cafe :=$platform_container/camera/platform_cleaner as Area2D
var score:=0
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
	
func _physics_process(delta : float) -> void:
	if player.position.y > camera.position.y:
		camera.position.y = player.position.y 
		score_update()

func delete_object(obstacle):
	if obstacle.is_in_group("player"):
		#get_tree().reload_current_scene()
		if score> GameManager.highscore:
			GameManager.highscore=score
		if get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")!=OK:
			print("je sais pas quoi mettre")
	elif obstacle.is_in_group("platform") or obstacle.is_in_group("enemies"):
		obstacle.queue_free()
		level_generator(1)
	
	
func _on_platform_cleaner_body_entered(body: Node2D) -> void:
	delete_object(body)

func score_update():
	score=camera_start_position+camera.position.y
	score_label.text = str(int(score))
	
func _on_died(reason: String) -> void:
	# Stoppe le jeu, affiche un panneau, enregistre highscore, etc.
	# Ou:
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")
