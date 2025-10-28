extends CanvasLayer
@onready var son :=$MusicIntro
# Called when the node enters the scene tree for the first time.
func _ready():
	self.hide()
	$MusicIntro.play()
	$MusicIntro.finished.connect(on_intro_finished)

	$LabelMort.start_typing.connect($TypingSfx.play)
	$LabelMort.stop_all.connect(_stop_everything)
	#$TypingSfx.finished.connect(_on_typing_sfx_finished) # optionnel

func on_intro_finished():
	$LabelMort.start_typing_text()

func _stop_everything():
	$MusicIntro.stop()
	$TypingSfx.stop()


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
