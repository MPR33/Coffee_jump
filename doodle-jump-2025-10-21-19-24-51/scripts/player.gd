extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -500.0
const INVULNERABILITY_BLINK_INTERVAL := 0.1

@onready var anim := $anim as AnimatedSprite2D
@onready var screen_size = get_viewport_rect().size

var invulnerable_to_cafe := false
var blink_timer := 0.0

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Gestion du clignotement si invulnérable
	if invulnerable_to_cafe:
		blink_timer -= delta
		if blink_timer <= 0.0:
			blink_timer = INVULNERABILITY_BLINK_INTERVAL
			anim.visible = not anim.visible
	else:
		anim.visible = true

	# Déplacement horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.scale.x = -direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Déplacement vertical
	var collision := move_and_collide(velocity * delta)
	if velocity.y > 0:
		anim.play("fall")
	else:
		anim.play("defaultidle")

	if collision:
		var collider = collision.get_collider()

		# Vérifie la présence du champ jumpforce de façon robuste
		var jump_force := 1.0
		if collider and "jumpforce" in collider:
			jump_force = collider.jumpforce

		velocity.y = JUMP_VELOCITY * jump_force

		if collider and collider.has_method("response"):
			collider.response()

		# 🟢 Si c'est une plateforme ressort : invulnérable aux gouttes
		if collider and collider.scene_file_path.ends_with("spring_platform.tscn"):
			invulnerable_to_cafe = true
			blink_timer = INVULNERABILITY_BLINK_INTERVAL
		elif collider:
			# 🟤 Retouche une plateforme normale → redevient vulnérable
			invulnerable_to_cafe = false
			anim.visible = true

	position.x = wrapf(position.x, 0, screen_size.x)


func die(reason := ""):
	# ⚠️ Ne pas mourir si la mort vient du café et qu’on est invulnérable
	if invulnerable_to_cafe and reason.begins_with("goutte de café"):
		return

	velocity = Vector2.ZERO
	GameManager._die(reason)
