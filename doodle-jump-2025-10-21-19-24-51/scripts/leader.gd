extends Panel
var tableau: Dictionary
var scores_only:=[]
var names_only := []
func _ready():
	self.visible=false
	_populate_leaderboard()

func _populate_leaderboard():
	var Scores = GameManager.sw_result
	var tableau = Scores.get("scores", [])

	# 1) Extraire deux listes propres
	for entry in tableau:
		scores_only.append(entry["score"])
		names_only.append(entry["player_name"])
	# 2) Remplir les labels
	for i in range(10):
		var label_path := "VBoxContainer/Label" + ("" if i == 0 else str(i+1))
		var lbl := get_node_or_null(label_path)
		if lbl == null:
			continue
		if i < names_only.size():
			lbl.text = "{0} — {1}".format([names_only[i], scores_only[i]])
			lbl.visible = true
		else:
			lbl.text = ""
			lbl.visible = false


func _on_button_pressed() -> void:
	self.visible=false
