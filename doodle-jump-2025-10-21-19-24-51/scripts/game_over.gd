extends CanvasLayer
@onready var son :=$son
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()

func gameover()-> void:
	self.show()
	son.play()
	get_tree().paused=true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_retry_pressed() -> void:
	get_tree().paused=false
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://main.tscn")
