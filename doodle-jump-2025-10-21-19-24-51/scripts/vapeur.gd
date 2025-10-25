extends "res://scripts/platform.gd"

var direction := Vector2.RIGHT
var gravity := -20.0               # gravité négative = monte
var velocity := Vector2.ZERO
@export var SPEED := 100
@onready var screen_size := get_viewport_rect().size
@onready var anim := $anim as AnimatedSprite2D

# --- AJOUTS POUR DIFFICULTÉ ---
@export var base_gravity := -20.0  # gravité "de base" (négative = vers le haut)
@export var max_speed := -600.0    # vitesse verticale max (négative)
var difficulty_factor := 1.0

func _ready():
	anim.play("moving")
	add_to_group("enemies")    # <-- pour que platform_cleaner la nettoie comme les autres


func apply_difficulty(d: float) -> void:
	difficulty_factor=d

func movement(delta):
	velocity.y += gravity * delta     # accélère verticalement (monte)
	# bornes (pour éviter des vitesses folles si la gravité devient très grande)
	velocity.y = max(velocity.y, max_speed * difficulty_factor)
	position += velocity * delta      # applique le mouvement

func _physics_process(delta: float) -> void:
	movement(delta)

func response():
	emit_signal("delete_object", self)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager._die("")
