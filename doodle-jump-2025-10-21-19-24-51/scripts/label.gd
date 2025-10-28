extends Label

signal start_typing                 # ← le parent la déclenchera
signal stop_all                     # ← pour le Retry

@export var chars_per_second: float = 20.0

var full_text := ""
var _timer := 0.0
var _index := 0
var _typing_active := false

func _ready():
	text = ""
	GameManager.reset_txt.connect(reset_text)

func _process(delta):
	if not _typing_active:
		return

	if _index >= full_text.length():
		emit_signal("stop_all") # pour stopper aussi TypingSfx
		return

	_timer += delta
	if _timer >= 1.0 / chars_per_second:
		_timer = 0.0
		text += full_text[_index]
		_index += 1

func start_typing_text():
	full_text = "☠️ Mort : %s" % GameManager.raison
	_typing_active = true
	_index = 0
	_timer = 0.0
	text = ""
	emit_signal("start_typing")  # ← déclenche son 2

func reset_text():
	_typing_active = false
	_index = 0
	_timer = 0.0
	text = ""
	emit_signal("stop_all") # ← tout stoppe
