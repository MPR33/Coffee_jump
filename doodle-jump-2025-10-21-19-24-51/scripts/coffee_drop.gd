extends Area2D

@export var speed: float = 600.0
@export var kill_group: StringName = &"player"
@export var lifetime: float = 8.0

var _life: float = 0.0

func _ready() -> void:
	monitoring = true
	connect("body_entered", _on_body_entered)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	position.y += speed * delta
	_life += delta
	if _life > lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(kill_group) and body.has_method("die"):
		body.die()
