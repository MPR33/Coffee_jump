extends LineEdit


func _ready():
	text = "Nom:"  # texte visible par défaut

	focus_entered.connect(func():
		if text == "Nom:":
			clear()  # efface seulement si le texte est encore celui de départ
	)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
