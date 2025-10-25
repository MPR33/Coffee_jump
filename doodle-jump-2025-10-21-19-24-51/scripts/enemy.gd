extends "res://scripts/platform.gd"

var direction:= Vector2.RIGHT
var gravity := 20
var velocity := Vector2.ZERO
@export var SPEED := 100
@onready var screen_size:= get_viewport_rect().size
@onready var anim:= $anim as AnimatedSprite2D
func _ready():
	anim.play("moving")
func movement(delta):
	velocity.y += gravity * delta   # accélère verticalement
	position += velocity * delta    # applique le mouvement
		
func _physics_process(delta: float) -> void:
	movement(delta)

#func response():
	#emit_signal("delete_object",self)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
