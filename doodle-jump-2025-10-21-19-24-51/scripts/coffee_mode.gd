extends Node2D

@onready var platform_container := $platform_container_coffee
@onready var platform := $platform_container_coffee/platform_coffee
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player := $platform_container_coffee/coffee_bean as CharacterBody2D
@onready var score_label := $platform_container_coffee/camera/CanvasLayer/score as Label
@onready var camera := $platform_container_coffee/camera as Camera2D
@onready var cafe := $platform_cleaner_coffee as Area2D
@onready var cafe2 := $platform_cleaner_coffee2 as Area2D
@onready var ui := $UI

@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform_coffee.tscn"),
	preload("res://platforms/ice.tscn"),
	preload("res://actors/vapeur.tscn")
]
@onready var Warning := preload("res://ui/warning_sign_ui.tscn")
@onready var viewport_size := get_viewport().get_visible_rect().size

var last_platform_is_cloud := false

func _ready() -> void:
	randomize()
	level_generator(100)
	score_update()

	GameManager.died.connect(_on_died)

	if not GameManager.game_started:
		GameManager.start_game()


func _physics_process(delta: float) -> void:
	if not GameManager.game_started:
		return

	# Suivi caméra
	if player.position.y > camera.position.y:
		camera.position.y = player.position.y
		score_update()
	elif player.position.y < camera.position.y - 130:
		camera.position.y = player.position.y

	# Suppression objets trop bas
	for child in platform_container.get_children():
		if child.is_in_group("platform") or child.is_in_group("enemies"):
			if child.global_position.y < cafe.global_position.y - 200:
				child.call_deferred("queue_free")
				level_generator(1)


# ---------------------------------------------------------------------
# GÉNÉRATION DE PLATEFORMES
# ---------------------------------------------------------------------
func level_generator(amount: int) -> void:
	for i in range(amount):
		var new_type: int = randi() % 3
		var new_platform: Node2D

		match new_type:
			0:
				platform_initial_position_y += randf_range(36, 54)
				new_platform = platform_scene[0].instantiate()
				new_platform.position = Vector2(randf_range(15, 170), platform_initial_position_y)
				platform_container.call_deferred("add_child", new_platform)

			1:
				platform_initial_position_y += randf_range(36, 54)
				new_platform = platform_scene[1].instantiate()
				new_platform.position = Vector2(randf_range(20, 165), platform_initial_position_y)
				platform_container.call_deferred("add_child", new_platform)

			2:
				if GameManager.score_coffee > 0:
					platform_initial_position_y += randf_range(36, 54)
					var x := randf_range(20, 165)
					new_platform = platform_scene[2].instantiate()

					# Ajout du panneau d’avertissement (vapeur)
					var w := Warning.instantiate()
					w.anchors_preset = Control.PRESET_BOTTOM_WIDE
					w.global_position.x = x
					w.global_position.y = viewport_size.y - 3000
					ui.add_child(w)

					new_platform.position = Vector2(x, platform_initial_position_y)
					platform_container.call_deferred("add_child", new_platform)


# ---------------------------------------------------------------------
# COLLISIONS ET SUPPRESSION
# ---------------------------------------------------------------------
func delete_object(obstacle: Node) -> void:
	if obstacle.is_in_group("player"):
		GameManager._die("tombé dans le café (Coffee)")
	elif obstacle.is_in_group("platform") or obstacle.is_in_group("enemies"):
		obstacle.call_deferred("queue_free")
		level_generator(1)

func _on_platform_cleaner_coffee_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		call_deferred("delete_object", body)

func _on_platform_cleaner_coffee_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not body.is_in_group("vapeur"):
		call_deferred("delete_object", body)


# ---------------------------------------------------------------------
# SCORE
# ---------------------------------------------------------------------
func score_update() -> void:
	GameManager.score_coffee = max(GameManager.score_coffee, player.position.y)
	score_label.text = str(int(GameManager.score_coffee - GameManager.score_sugar))


# ---------------------------------------------------------------------
# MORT
# ---------------------------------------------------------------------
func _on_died(reason: String) -> void:
	print("Mort détectée dans Coffee Mode : %s" % reason)
