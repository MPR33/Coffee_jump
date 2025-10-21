extends CharacterBody2D

@export var speed : float = 240.0
@export var jump_strength : float = 800.0
@export var gravity : float = 1400.0

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

	# Déplacement physique
	move_and_slide()

	# Meurt si tombe trop bas
	if global_position.y > 1200:
		get_tree().reload_current_scene()
