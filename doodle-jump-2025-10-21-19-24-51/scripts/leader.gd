extends Panel

var scores_only: Array[int] = []
var names_only: Array[String] = []

func _ready():
	self.visible = false
	# évite de peupler ici si l’API n’a pas encore répondu
	# on le fera quand on ouvre le panel

func open() -> void:
	self.visible = true
	await _populate_leaderboard()  # rafraîchit à l'ouverture

func _populate_leaderboard() -> void:
	scores_only.clear()
	names_only.clear()

	var tableau = GameManager.sw_result.get("scores", [])

	# Deduplicate + keep best score
	var best_by_player := {}
	for entry in tableau:
		var p = entry["player_name"]
		var s = int(entry["score"])
		if not best_by_player.has(p) or s > best_by_player[p]:
			best_by_player[p] = s

	# Build sorted unique list
	var unique_sorted := []
	for p in best_by_player.keys():
		unique_sorted.append({"player_name": p, "score": best_by_player[p]})
	unique_sorted.sort_custom(func(a, b): return a["score"] > b["score"])

	# Fill UI lists
	for entry in unique_sorted:
		scores_only.append(entry["score"])
		names_only.append(entry["player_name"])

	# Affichage dans les labels
	for i in range(10):
		var label_path := "VBoxContainer/Label" + ("" if i == 0 else str(i+1))
		var lbl := get_node_or_null(label_path)
		if lbl == null:
			continue
		if i < names_only.size():
			lbl.text = "%s — %d" % [names_only[i], scores_only[i]]
			lbl.visible = true
		else:
			lbl.text = ""
			lbl.visible = false


func _on_button_pressed() -> void:
	self.visible = false
