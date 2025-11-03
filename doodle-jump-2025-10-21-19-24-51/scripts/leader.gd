extends Panel

var scores_only: Array[int] = []
var names_only: Array[String] = []

func _ready():
	self.visible = false

func open() -> void:
	self.visible = true
	await _populate_leaderboard()  # rafraîchit à l'ouverture

func _populate_leaderboard() -> void:
	var board = await LootLocker.get_scores(1)
	if board.ok:
		for item in board.items:
			print("%d. %s (%s) - %s" % [
				int(item.rank),
				item.get("player_name", "Anon"),
				str(item.player_id),
				str(item.score)
			])
	else:
		push_error("Lecture leaderboard a échoué: %s" % board.error)
	#scores_only.clear()
	#names_only.clear()
	## On récupère plus large (50) pour laisser la marge à la déduplication
	#var res: Dictionary = await Lootlocker.get_scores(10)
	#if not res.get("ok", false):
		#push_error("Lecture leaderboard a échoué: %s" % res.get("error", ""))
		#return
#
	#var items: Array = res.get("items", [])
#
	## Déduplication par player_name (ou fallback sur player_id)
	#var best_by_player: Dictionary = {}  # name -> best score (int)
	#for item in items:
		#var pname: String = ""
		#if item.has("player_name") and typeof(item["player_name"]) == TYPE_STRING and String(item["player_name"]).strip_edges() != "":
			#pname = String(item["player_name"])
		#else:
			#pname = "Anon#" + String(item.get("player_id", ""))
#
		#var sc: int = int(item.get("score", 0))
		#if not best_by_player.has(pname) or sc > int(best_by_player[pname]):
			#best_by_player[pname] = sc
#
	## Construction + tri descendant par score
	#var unique_sorted: Array = []
	#for p in best_by_player.keys():
		#unique_sorted.append({ "player_name": String(p), "score": int(best_by_player[p]) })
#
	#unique_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		#return int(a["score"]) > int(b["score"])
	#)
#
	## Limite à 10 et remplissage des listes UI
	#var top_n: int = min(10, unique_sorted.size())
	#for i in top_n:
		#var entry: Dictionary = unique_sorted[i]
		#scores_only.append(int(entry["score"]))
		#names_only.append(String(entry["player_name"]))
	#print(scores_only)
	## Affichage dans les labels
	#for i in range(10):
		#var label_path := "VBoxContainer/Label" + ("" if i == 0 else str(i+1))
		#var lbl := get_node_or_null(label_path)
		#if lbl == null:
			#continue
		#if i < names_only.size():
			#lbl.text = "%s — %d" % [names_only[i], scores_only[i]]
			#lbl.visible = true
		#else:
			#lbl.text = ""
			#lbl.visible = false


func _on_button_pressed() -> void:
	self.visible = false


func _on_leaderboardhttp_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var txt: String = body.get_string_from_utf8()

	# ✅ On stocke le JSON comme Variant puis on cast plus tard
	var parsed: Variant = JSON.parse_string(txt)

	# ✅ safety: on vérifie qu'on a bien un tableau
	if typeof(parsed) != TYPE_ARRAY:
		print("Erreur: données invalides ->", parsed)
		return

	var arr: Array = parsed

	# Déduplication : garder le meilleur score par joueur
	var best := {} # Dictionary player -> score

	for e in arr:
		if typeof(e) == TYPE_DICTIONARY and e.has("player") and e.has("score"):
			var player := str(e["player"]).strip_edges()
			if player == "":
				continue
			var score := float(e["score"])
			if not best.has(player) or score > best[player]:
				best[player] = score

	# Reconstruction du tableau scoreboard
	var scoreboard: Array = []
	for p in best.keys():
		scoreboard.append({"player": p, "score": best[p]})

	# Tri décroissant
	scoreboard.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))

	# Remplissage des labels 1–10
	for i in range(10):
		var path := "VBoxContainer/Label" + ("" if i == 0 else str(i + 1))
		var lbl: Label = get_node_or_null(path)
		if lbl:
			if i < scoreboard.size():
				var s = scoreboard[i]
				lbl.text = "%d. %s : %d" % [i + 1, s["player"], int(s["score"])]
			else:
				lbl.text = ""
	
