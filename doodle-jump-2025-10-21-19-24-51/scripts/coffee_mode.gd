extends Node2D

@onready var platform_container := $platform_container_coffee
@onready var platform := $platform_container_coffee/platform_coffee
@onready var platform_initial_position_y: float = (platform as Node2D).position.y
@onready var player := $platform_container_coffee/coffee_bean as CharacterBody2D
@onready var score_label := $platform_container_coffee/camera/CanvasLayer/score as Label
@onready var camera := $platform_container_coffee/camera as Camera2D
@onready var cafe := $platform_cleaner_coffee as Area2D
@onready var ui := $UI

@export var platform_scene: Array[PackedScene] = [
	preload("res://platforms/platform_coffee.tscn"),
	preload("res://platforms/ice.tscn"),
	preload("res://platforms/picots.tscn")]
@onready var cafe2 := $platform_cleaner_coffee2 as Area2D

const VAPEUR_SCENE: PackedScene = preload("res://actors/vapeur.tscn")

# Le score auquel on considère que la difficulté est à 100%
const SCORE_AT_MAX_DIFFICULTY := 4000.0

# Intervalle de spawn borné par la difficulté (linéaire)
const MIN_INTERVAL := 0.6
const MAX_INTERVAL := 2.5

var _rng := RandomNumberGenerator.new()
var _spawn_timer: Timer
@onready var Warning := preload("res://ui/warning_sign_ui.tscn")
@onready var viewport_size := get_viewport().get_visible_rect().size

var last_platform_is_cloud := false

func _ready() -> void:
	randomize()
	level_generator(30)
	score_update()
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(spawn)

	# premier spawn immédiat
	spawn()
	GameManager.died.connect(_on_died)

	if not GameManager.game_started:
		GameManager.start_game()
func _get_difficulty() -> float:
	var s := float(GameManager.score_coffee)
	var d := s / SCORE_AT_MAX_DIFFICULTY
	if d > 1.0:
		d = 1.0
	if d < 0.0:
		d = 0.0
	return d


func _get_spawn_interval() -> float:
	var d:=_get_difficulty()
	# interpolation linéaire: quand d=0 => MAX_INTERVAL, quand d=1 => MIN_INTERVAL
	return MAX_INTERVAL + (MIN_INTERVAL - MAX_INTERVAL) * d
func spawn() -> void:
	var d := _get_difficulty()
	var x := _rng.randf_range(20.0, 160.0)
	var y := cafe2.position.y+200
	# Premier timer (warning)
	var t1 := get_tree().create_timer(5 * (1 - d))
	t1.timeout.connect(func():
		var w := Warning.instantiate()
		ui.add_child(w)
		w.set_anchors_preset(Control.PRESET_CENTER)
		if w.has_method("setup"):
			w.setup(x, 2)

	# Deuxième timer (vapeur)
		var t := get_tree().create_timer(2)
		t.timeout.connect(func():
			var v := VAPEUR_SCENE.instantiate()
			v.position = Vector2(x, y)
			if v.has_method("apply_difficulty"):
				v.apply_difficulty(d)
			add_child(v)

			var interval := _get_spawn_interval()
			_spawn_timer.wait_time = interval + 1
			_spawn_timer.start()
		))

func _physics_process(delta: float) -> void:
	if not GameManager.game_started:
		return

	# Suivi caméra
	if player.position.y > camera.position.y - 100:
		camera.position.y = player.position.y + 100
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
	var d:=_get_difficulty()
	for i in range(amount):
		var new_type: int = randi() % 3
		var new_platform: Node2D
		match new_type:
			0:
				platform_initial_position_y += randf_range(36, 54)
				print(_get_difficulty())
				new_platform = platform_scene[0].instantiate()
				new_platform.position = Vector2(randf_range(15, 170), platform_initial_position_y)
				platform_container.call_deferred("add_child", new_platform)

			1:
				platform_initial_position_y += randf_range(36, 54)
				print(_get_difficulty())
				new_platform = platform_scene[1].instantiate()
				new_platform.position = Vector2(randf_range(20, 165), platform_initial_position_y)
				platform_container.call_deferred("add_child", new_platform)

			2:
				if GameManager.score_coffee > 0:
					print(_get_difficulty())
					var test:=randf_range(0,1)
					platform_initial_position_y += randf_range(36, 54)
					if test<=d:
						new_platform = platform_scene[2].instantiate()
					else :
						new_platform = platform_scene[0].instantiate()
					new_platform.position = Vector2(randf_range(20, 165), platform_initial_position_y)
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
