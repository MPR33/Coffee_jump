extends "res://scripts/platform.gd"

var direction := Vector2.RIGHT
var gravity := -20.0
var velocity := Vector2.ZERO
@export var SPEED := 100
@onready var screen_size := get_viewport_rect().size
@onready var anim := $anim as AnimatedSprite2D

@export var base_gravity := -200.0
@export var base_speed := -300.0
@export var max_speed := -1000.0
var difficulty_factor := 1.0

@export var TRAVERSE_TIME := 5.0  # durée fixe de traversée de l'écran

var ready_done := false  # indique quand le nœud est prêt

func _ready():
	anim.play("moving")
	add_to_group("enemies")
	ready_done = true
	_update_length()

func apply_difficulty(d: float) -> void:
	difficulty_factor = d
	# Si le nœud n’est pas encore prêt, on attendra _ready()
	if ready_done:
		_update_length()

func _update_length() -> void:
	if anim == null:
		push_warning("⚠️ anim non trouvé pour la vapeur, impossible d’ajuster la longueur.")
		return

	var v := base_speed * (1 - difficulty_factor) + difficulty_factor * max_speed
	var H := screen_size.y
	var L :float= TRAVERSE_TIME * abs(v) - H
	L = max(L, 50.0)

	anim.scale.y = L / H

func movement(delta):
	velocity.y = base_speed * (1 - difficulty_factor) + difficulty_factor * max_speed
	position += velocity * delta

func _physics_process(delta: float) -> void:
	movement(delta)

func response():
	emit_signal("delete_object", self)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager._die("")
