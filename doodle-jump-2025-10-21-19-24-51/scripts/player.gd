extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -500.0

@onready var anim := $anim as AnimatedSprite2D
@onready var screen_size = get_viewport_rect().size

var invulnerable_to_cafe := false

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Déplacement horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED      # <-- indispensable pour bouger
		anim.flip_h = direction < 0         # <-- retourne le sprite sans toucher à l'échelle
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED) 

	# Mouvement + choix d’animation
	var collision := move_and_collide(velocity * delta)

	# --- Gestion des animations ---
	if invulnerable_to_cafe:
		# Tant qu'on est invulnérable, on force le tourbillon (spin)
		if anim.animation != "spin":
			anim.play("spin")
	else:
		# Sinon, état normal : chute vs idle
		if velocity.y > 0:
			if anim.animation != "fall":
				anim.play("fall")
		else:
			if anim.animation != "defaultidle":
				anim.play("defaultidle")

	# --- Gestion des collisions & rebond ---
	if collision:
		var collider = collision.get_collider()

		# Vérifie la présence du champ jumpforce de façon robuste
		var jump_force := 1.0
		if collider and "jumpforce" in collider:
			jump_force = collider.jumpforce

		velocity.y = JUMP_VELOCITY * jump_force

		if collider and collider.has_method("response"):
			collider.response()

		# 🟢 Si c'est une plateforme ressort : active l'invulnérabilité + spin
		if collider and collider.scene_file_path.ends_with("spring_platform.tscn"):
			invulnerable_to_cafe = true
			# Lance l'anim immédiatement si ce n'est pas déjà le cas
			if anim.animation != "spin":
				anim.play("spin")
		elif collider:
			# 🟤 Plateforme normale → redevient vulnérable (anim redeviendra idle/fall)
			invulnerable_to_cafe = false

	# Wrap horizontal
	position.x = wrapf(position.x, 0, screen_size.x)

func die(reason := ""):
	# ⚠️ Ne pas mourir si la mort vient du café et qu’on est invulnérable
	if invulnerable_to_cafe and reason.begins_with("goutte de café"):
		return
	GameManager._die(reason)
