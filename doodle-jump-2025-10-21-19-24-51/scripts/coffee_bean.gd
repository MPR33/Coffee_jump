extends CharacterBody2D

# --- Réglages généraux ---
@export var gravity: float = 600.0
@export var terminal_fall_speed: float = 450.0

# Même vitesse max partout (tu peux ajuster)
@export var max_speed: float = 220.0

# --- Accélérations / Décélérations (px/s²) ---
# Sol (normal)
@export var accel_ground: float = 1000.0
@export var decel_ground: float = 2400.0
# Glace (inertie la + forte => accélération plus faible, freinage très faible)
@export var accel_ice: float = 600.0
@export var decel_ice: float = 200.0
# Air (inertie > sol mais < glace, avec un petit air-control)
@export var accel_air: float = 900.0
@export var decel_air: float = 400.0

# --- Animation ---
@onready var anim: AnimatedSprite2D = $anim_coffee
@onready var screen_size: Vector2 = get_viewport_rect().size

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, terminal_fall_speed)
	else:
		velocity.y = 0.0

	# Input horizontal
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0:
		# flip horizontal propre
		anim.flip_h = dir < 0

	# Détection de la glace via groupes (uniquement si on est au sol)
	var on_ice := false
	if is_on_floor():
		var slide_count := get_slide_collision_count()
		for i in range(slide_count):
			var c := get_slide_collision(i)
			if c and c.get_collider() and c.get_collider().is_in_group("ice"):
				on_ice = true
				break

	# Choix des coefficients d'accélération / décélération selon l'état
	var a: float
	var d: float
	if is_on_floor():
		if on_ice:
			a = accel_ice
			d = decel_ice
		else:
			a = accel_ground
			d = decel_ground
	else:
		a = accel_air
		d = decel_air

	# Cible de vitesse horizontale
	var target_vx := (dir * max_speed) if dir != 0 else 0.0

	# Accélération vers la cible si input, sinon freinage progressif
	if dir != 0:
		velocity.x = move_toward(velocity.x, target_vx, a * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, d * delta)

	# Déplacement
	move_and_slide()

	# Animation simple : idle au sol, fall en l'air (tu peux enrichir si tu ajoutes "run"/"slide")
	if not is_on_floor():
		if anim.animation != "fall":
			anim.play("fall")
	else:
		if anim.animation != "idle":
			anim.play("idle")

	# Wrap horizontal (écran torique en X)
	position.x = wrapf(position.x, 0.0, screen_size.x)

func die():
	# Appel différé pour éviter les suppressions / changements pendant la phase physique
	velocity = Vector2.ZERO
	call_deferred("_notify_death")

func _notify_death():
	# Laisse inchangé si ton GameManager s'attend à une string raison
	velocity = Vector2.ZERO
	GameManager._die("Terrible")
