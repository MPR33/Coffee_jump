extends CharacterBody2D

var speed_normal := 100
var speed_ice := 500  # vitesse sur glace

@onready var anim := $anim_coffee as AnimatedSprite2D
@onready var screen_size = get_viewport_rect().size

func _physics_process(delta: float) -> void:
	# Gravité simple
	if not is_on_floor():
		velocity.y = min(velocity.y + 600 * delta, 450)  # 450 = vitesse max de chute
	else:
		velocity.y = 0

	# Déterminer direction input
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0:
		anim.scale.x = -dir  # retourne le sprite

	# DÉTECTION GLACE
	var on_ice := false
	if is_on_floor():
		for i in range(get_slide_collision_count()):
			var c := get_slide_collision(i)
			if c.get_collider().is_in_group("ice"):
				on_ice = true
				break

	# Vitesse horizontale
	if dir != 0:
		velocity.x = dir * (speed_ice if on_ice else speed_normal)
	else:
		if not on_ice:
			velocity.x = move_toward(velocity.x, 0, 20)

	# Déplacement
	move_and_slide()

	# Animation
	if velocity.y == 0:
		anim.play("idle")
	else:
		anim.play("fall")

	# Empêcher de sortir de l'écran
	position.x = wrapf(position.x, 0, screen_size.x)


func die():
	velocity = Vector2.ZERO
	GameManager._die("")
