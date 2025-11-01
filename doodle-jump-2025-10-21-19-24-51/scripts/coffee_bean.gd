extends CharacterBody2D

# --- Réglages généraux ---
@export var gravity: float = 600.0
@export var terminal_fall_speed: float = 450.0
@export var max_speed: float = 220.0

# --- Accélérations / Décélérations ---
@export var accel_ground: float = 1000.0
@export var decel_ground: float = 2400.0
@export var accel_ice: float = 600.0
@export var decel_ice: float = 200.0
@export var accel_air: float = 900.0
@export var decel_air: float = 400.0

# --- Animation / Sprite ---
@onready var anim: AnimatedSprite2D = $anim_coffee
@onready var screen_size: Vector2 = get_viewport_rect().size
@export var run_anim_min_speed: float = 20.0

# Orientation mémorisée (garde le flip pendant la glissade)
var facing := 1

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, terminal_fall_speed)
	else:
		# on ne remet pas forcément y=0 ici : on va le faire quand on détecte le contact
		pass

	# Input horizontal
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0:
		facing = sign(dir)
	anim.flip_h = facing < 0

	# Détection glace (si au sol)
	var on_ice := false
	if is_on_floor():
		var slide_count0 := get_slide_collision_count()
		for i in range(slide_count0):
			var c0 := get_slide_collision(i)
			if c0 and c0.get_collider() and c0.get_collider().is_in_group("ice"):
				on_ice = true
				break

	# Coeffs a/d selon état
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

	# Vitesse horizontale cible
	var target_vx := (dir * max_speed) if dir != 0 else 0.0

	# Approche / freinage
	if dir != 0:
		velocity.x = move_toward(velocity.x, target_vx, a * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, d * delta)

	# --- Déplacement physique ---
	# (Laisse Godot détecter les collisions)
	move_and_slide()

	# --- Détection de "contact sol" même si diagonal ---
	var landed_this_frame := false
	var slide_count := get_slide_collision_count()
	for i in range(slide_count):
		var c := get_slide_collision(i)
		if c:
			# normale pointant "vers le haut" -> c'est raisonnablement un sol/slope
			# -0.5 ~ 60° max ; ajustable si tes pentes sont raides
			if c.get_normal().y < -0.5:
				landed_this_frame = true
				break

	# Si on a touché une plateforme, on sort du fall immédiatement
	if landed_this_frame:
		velocity.y = 0.0  # annule la descente pour éviter la persistance de fall

	# --- ANIMATION ---
	if not landed_this_frame and not is_on_floor():
		# Toujours en l'air et pas de contact sol ce frame -> fall
		if anim.animation != "fall":
			anim.play("fall")
	else:
		# Au sol (ou on vient de toucher le sol)
		if abs(velocity.x) > run_anim_min_speed:
			if anim.animation != "run":
				anim.play("run")
		else:
			if anim.animation != "idle":
				anim.play("idle")

	# Wrap horizontal
	position.x = wrapf(position.x, 0.0, screen_size.x)

func die():
	call_deferred("_notify_death")

func _notify_death():
	GameManager._die("Terrible")
