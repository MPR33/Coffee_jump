extends Panel
@onready var enter_btn: Button = $Button
var default_text := ""  # tu peux mettre "Nom..." si tu as un placeholder
var has_been_edited := false
# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible=false
	default_text = $LineEdit.text
	$LineEdit.text_changed.connect(func(_new_text): has_been_edited = true)
	get_parent().connect("panel", Callable(self, "set_visible").bind(true))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	if $LineEdit.text.strip_edges() == "" or not has_been_edited:
		return
	else:
		GameManager.nomRempli=true
		self.visible=false
		GameManager.player_name=$LineEdit.text
