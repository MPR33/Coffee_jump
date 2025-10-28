extends Panel
@onready var enter_btn: Button = $Button

# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible=false
	get_parent().connect("panel", Callable(self, "set_visible").bind(true))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	if $LineEdit.text.strip_edges() == "":
		return
	else:
		GameManager.nomRempli=true
		self.visible=false
		GameManager.player_name=$LineEdit.text
