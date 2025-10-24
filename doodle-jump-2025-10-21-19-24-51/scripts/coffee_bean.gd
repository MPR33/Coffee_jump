extends CharacterBody2D

var jump_force := 400
var speed :=100

@onready var anim:= $anim_coffee as AnimatedSprite2D
@onready var screen_size = get_viewport_rect().size
@export var max_speed: float = 220.0          # vitesse horizontale max
@export var accel_ground: float = 10.0        # inertie au sol (plus réactif)
@export var accel_air: float = 7.0            # inertie en l’air (un poil plus “mou”)
@export var damp_ground: float = 12.0         # ralenti si on lâche les touches (sol)
@export var damp_air: float = 6.0             # ralenti si on lâche les touches (air)

@export var gravity: float = 380.0            # gravité faible -> chute lente
@export var terminal_velocity: float = 230.0  # vitesse limite de chute (IMPORTANT)
@export var ground_slide_speed: float = 60.0  # vitesse verticale quand on “colle” au sol
@export var floor_snap: float = 8.0           # aide à rester collé aux plateformes

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > terminal_velocity:
			velocity.y = terminal_velocity
	else:
		velocity.y = 0
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		var target_speed:= direction*max_speed
		var accel := accel_ground if is_on_floor() else accel_air
		velocity.x = lerp(velocity.x, target_speed, accel * delta)
		anim.scale.x=-direction
	elif absf(direction) < 0.01:
		var damp := damp_ground if is_on_floor() else damp_air
		velocity.x = lerp(velocity.x, 0.0, damp * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	var collision = move_and_collide(velocity*delta)
	if collision:
		velocity.y =0
	if velocity.y == 0:
		anim.play("idle")
	else:
		anim.play("fall")
	if is_on_floor() and velocity.y > ground_slide_speed:
		velocity.y = ground_slide_speed
	position.x=wrapf(position.x,0, screen_size.x)
	
func die():
	velocity=Vector2.ZERO
	set_collision_mask_value(2,false)
	GameManager.game_started = false
