extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -500.0

@onready var anim:= $anim as AnimatedSprite2D
@onready var screen_size = get_viewport_rect().size


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.scale.x=-direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	var collision = move_and_collide(velocity*delta)
	if velocity.y >0:
		anim.play("fall")
	else:
		anim.play("defaultidle")
	if collision:
		velocity.y = +JUMP_VELOCITY*collision.get_collider().jumpforce
		if collision.get_collider().has_method("response"):
			collision.get_collider().response()

	position.x=wrapf(position.x,0, screen_size.x)
	
	
func die():
	velocity=Vector2.ZERO
	set_collision_mask_value(2,false)
	#GameManager.game_started = false
