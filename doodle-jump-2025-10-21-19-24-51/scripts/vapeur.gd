extends "res://scripts/platform.gd"

var direction := Vector2.RIGHT
var gravity := -20.0
var velocity := Vector2.ZERO
@export var SPEED := 100
@onready var screen_size := get_viewport_rect().size
@onready var anim := $anim as AnimatedSprite2D
@onready var hitbox_collision := $hitbox/collision as CollisionShape2D

@export var base_speed := -300.0 
@export var max_speed := -1000.0
var difficulty_factor := 1.0

@export var TRAVERSE_TIME := 5.0  # durée fixe pour traverser l'écran

var ready_done := false

func _ready():
	anim.play("moving")
	add_to_group("enemies")
	ready_done = true
	_update_length()

func apply_difficulty(d: float) -> void:
	difficulty_factor = d
	if ready_done:
		_update_length()

func _update_length() -> void:
	if anim == null or hitbox_collision == null:
		push_warning("⚠️ anim ou hitbox non trouvée pour la vapeur.")
		return

	# Calcule la vitesse selon la difficulté
	var v := base_speed * (1 - difficulty_factor) + difficulty_factor * max_speed
	var H := screen_size.y
	var L : float = TRAVERSE_TIME * abs(v) - H
	L = max(L, 50.0)

	# Ajuste la hauteur visuelle de la vapeur
	anim.scale.y = L / H

	# 🟢 Ajuste la hitbox pour qu'elle épouse le sprite affiché
	var tex := anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	if tex and hitbox_collision.shape is RectangleShape2D:
		var tex_size := tex.get_size() * anim.scale
		hitbox_collision.shape.size = tex_size
	elif tex and hitbox_collision.shape is CapsuleShape2D:
		var tex_size := tex.get_size() * anim.scale
		hitbox_collision.shape.height = tex_size.y
	else:
		push_warning("⚠️ Forme de collision inattendue pour la vapeur : %s" % hitbox_collision.shape)

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
