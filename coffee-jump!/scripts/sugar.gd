extends CharacterBody2D

@export var speed : float = 240.0
@export var jump_strength : float = 800.0
@export var gravity : float = 1400.0
var max_height := 0.0
var score := 0
signal score_changed(score: int)

func _ready():
	# Initialise la hauteur et le score
	max_height = position.y
	score = 0

func _physics_process(delta):
	# Gravité
	velocity.y += gravity * delta

	# Mouvement gauche/droite
	var dir = 0
	if Input.is_action_pressed("move_left"):
		dir -= 1
	if Input.is_action_pressed("move_right"):
		dir += 1
	velocity.x = dir * speed

	# Si sur le sol, saute automatiquement
	if is_on_floor():
		velocity.y = -jump_strength
	position.x=wrapf(position.x,-520, 520)
	
		# Plus le joueur monte, plus y diminue (dans Godot, le haut = y plus petit)
	if position.y < max_height:
		max_height = position.y
		# Tu peux convertir en score positif (car plus haut = plus petit y)
		score = int(-max_height)
		score_changed.emit(score)  # envoie le signal

	# Déplacement physique
	move_and_slide()

	# Meurt si tombe trop bas
	if global_position.y > 1200:
		get_tree().reload_current_scene()
