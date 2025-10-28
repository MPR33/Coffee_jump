extends Label

@export var full_text: String
@export var chars_per_second: float = 20.0
@export var sfx: AudioStream = null

var _timer := 0.0
var _index := 0
var _player: AudioStreamPlayer = null

func _ready():
	text = ""
	GameManager.reset_txt.connect(reset_text)
func _process(delta):
	await get_tree().create_timer(4.8).timeout
	full_text = "☠️ Mort : %s" % GameManager.raison

	# -- FIN DU TEXTE --
	if _index >= full_text.length():
		if _player and _player.playing:
			_player.stop()  # ✅ Stop du son quand terminé
		return

	# -- DÉBUT DU SON SI PAS ENCORE LANCÉ --
	if sfx and (_player == null or not _player.playing):
		_player = AudioStreamPlayer.new()
		_player.stream = sfx
		add_child(_player)
		_player.play(10.16) 

	# -- ANIMATION DU TEXTE --
	_timer += delta
	if _timer >= 1.0 / chars_per_second:
		_timer = 0.0
		text += full_text[_index]
		_index += 1


func reset_text():
	text = ""
	_index = 0
	_timer = 0.0
	full_text=""
