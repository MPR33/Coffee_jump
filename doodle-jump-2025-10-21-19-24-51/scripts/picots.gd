extends "res://scripts/platform.gd"
@onready var anim: AnimatedSprite2D = $anim
@onready var shape: CollisionShape2D = $hitbox/collision

func _ready() -> void:           # <- important si le parent fait des choses en _ready
	anim.frame_changed.connect(_on_frame_changed)
	anim.play()                 # ou anim.play("le_nom_de_ton_anim") si plusieurs
	_on_frame_changed()         # init de la hitbox selon la frame

func _on_frame_changed() -> void:
	# frame 0 = safe → on désactive la hitbox
	shape.disabled = (anim.frame == 0)
	# Alternative : $hitbox.monitoring = (anim.frame != 0)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager._die("Aïe les picots !")
