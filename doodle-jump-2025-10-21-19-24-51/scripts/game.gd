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




func level_generator(amount):
	for items in amount :
		var new_type = randi()%4
		#0 1 2
		platform_initial_position_y -= randf_range(36,54)
		var new_platform 
		
		if new_type==0 :
			new_platform= platform_scene[0].instantiate() as StaticBody2D
		elif new_type==1:
			new_platform= platform_scene[1].instantiate() as StaticBody2D
		elif new_type>=2 :
			if last_platform_is_cloud == false and last_platform_is_enemy==false:
				new_platform= platform_scene[new_type].instantiate() as StaticBody2D
				new_platform.connect("delete_object", self.delete_object)
				if new_type==2:
					last_platform_is_cloud=true
				else:
					last_platform_is_enemy=true
			else :
				new_platform= platform_scene[0].instantiate() as StaticBody2D
				last_platform_is_cloud=false
				last_platform_is_enemy=false

		if new_type != null and new_type!=3:
			new_platform.position = Vector2(randf_range(20,160), platform_initial_position_y)
			platform_container.call_deferred('add_child', new_platform)
		elif new_type !=null and new_type==3 and (last_platform_is_cloud == false and last_platform_is_enemy==false):
			new_platform.position = Vector2(randf_range(20,160), platform_initial_position_y)
			platform_container.call_deferred('add_child', new_platform)
		else:
			new_platform.position = Vector2(randf_range(20,160), platform_initial_position_y)
			platform_container.call_deferred('add_child', new_platform)
		


	
func _physics_process(delta : float) -> void:
	if player.position.y < camera.position.y:
		camera.position.y = player.position.y 
		score_update()

func delete_object(obstacle):
	if obstacle.is_in_group("player"):
		#get_tree().reload_current_scene()
		if GameManager.score> GameManager.highscore:
			GameManager.highscore=GameManager.score
		if get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")!=OK:
			print("je sais pas quoi mettre")
	elif obstacle.is_in_group("platform") or obstacle.is_in_group("enemies"):
		obstacle.queue_free()
		level_generator(1)
	
	
func _on_platform_cleaner_body_entered(body: Node2D) -> void:
	delete_object(body)

func score_update():
	GameManager.score+=camera_start_position-player.position.y
	score_label.text = str(int(GameManager.score))
	
func _on_died(reason: String) -> void:
	# Stoppe le jeu, affiche un panneau, enregistre highscore, etc.
	# Ou:
	get_tree().change_scene_to_file("res://scenes/titl_screen.tscn")
	


func _ready() -> void:
	randomize()
	level_generator(200)
	GameManager.died.connect(_on_died)
