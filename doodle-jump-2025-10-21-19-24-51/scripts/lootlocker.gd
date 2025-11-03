# LootLocker.gd
extends Node
## Autoload pour gérer l'auth invité LootLocker + leaderboard
## API publique minimale :
##   await LootLocker.push_score("Ayoub", 1234)
##   var res = await LootLocker.get_scores(10)

# === Paramètres à adapter ===
const GAME_KEY: String = "dev_b7856a8acc0a4caf96448bb69dad8860"
const LEADERBOARD_KEY: String = "32022"
const DEVELOPMENT_MODE: bool = true
const GAME_VERSION: String = "0.0.0.1"

# === État ===
var _session_token: String = ""
var _player_identifier: String = ""
var _http: HTTPRequest

# === Lifecycle ===
func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	# Précharge depuis le disque si déjà présent
	_player_identifier = _load_player_identifier()

# === API Publique ===

## Envoie un score au leaderboard en utilisant un player_name (string).
## Retourne { ok: true, data: <json> } ou { ok: false, error: "<msg>" }
func push_score(player_name: String, score: int) -> Dictionary:
	var ok = await _ensure_session()
	if not ok:
		return { "ok": false, "error": "Impossible d'ouvrir une session LootLocker." }

	# (Optionnel) définir/mettre à jour le nom du joueur
	var set_name = await _set_player_name(player_name)
	if not set_name.ok:
		# On log seulement, mais on tente quand même d'envoyer le score
		push_warning("SetName a échoué: %s" % set_name.error)

	# Submit score
	var url = "https://api.lootlocker.io/game/leaderboards/%s/submit" % LEADERBOARD_KEY
	var payload := { "score": str(score) }  # l'API accepte le score en string
	var res = await _request(url, HTTPClient.METHOD_POST, payload, true)
	return res

## Récupère la liste des scores (par défaut top 'count').
## Retourne { ok: true, items: [ {rank, player_id, score, player_name?}, ... ] }
## ou { ok: false, error: "<msg>" }
func get_scores(count: int = 10) -> Dictionary:
	var ok = await _ensure_session()
	if not ok:
		return { "ok": false, "error": "Impossible d'ouvrir une session LootLocker." }

	var url = "https://api.lootlocker.io/game/leaderboards/%s/list?count=%d" % [LEADERBOARD_KEY, count]
	var res = await _request(url, HTTPClient.METHOD_GET, null, true)
	if not res.ok:
		return res

	var items := []
	if res.has("data") and res.data.has("items"):
		for item in res.data.items:
			var out := {
				"rank": item.get("rank", 0),
				"player_id": item.get("player", {}).get("id", ""),
				"score": item.get("score", 0)
			}
			# Certains schémas incluent player.name ; si dispo on le remonte
			if item.has("player") and item.player is Dictionary and item.player.has("name"):
				out["player_name"] = item.player.name
			items.append(out)
	return { "ok": true, "items": items }

# === Interne : Auth / Player Name ===

## S'assure qu'on a un session_token valide (auth invité).
func _ensure_session() -> bool:
	if _session_token != "":
		return true

	# Construit la charge utile d'auth invite
	var payload: Dictionary = {
		"game_key": GAME_KEY,
		"game_version": GAME_VERSION,
		"development_mode": DEVELOPMENT_MODE
	}
	if _player_identifier.length() > 0:
		payload["player_identifier"] = _player_identifier

	var url = "https://api.lootlocker.io/game/v2/session/guest"
	var res = await _request(url, HTTPClient.METHOD_POST, payload, false)
	if not res.ok:
		return false

	# Récupère & persiste
	_session_token = res.data.get("session_token", "")
	_player_identifier = res.data.get("player_identifier", _player_identifier)
	if _player_identifier != "":
		_save_player_identifier(_player_identifier)

	return _session_token != ""

## Définit le nom du joueur (PATCH). Retourne {ok, data|error}
func _set_player_name(player_name: String) -> Dictionary:
	if player_name.strip_edges() == "":
		return { "ok": false, "error": "player_name vide." }
	var url = "https://api.lootlocker.io/game/player/name"
	var payload := { "name": player_name }
	return await _request(url, HTTPClient.METHOD_PATCH, payload, true)

# === Interne : HTTP utilitaire ===

## Effectue une requête HTTP et parse le JSON.
## include_session_headers = ajoute "x-session-token" si dispo.
func _request(url: String, method: int, body_obj: Variant = null, include_session_headers: bool = false) -> Dictionary:
	var headers: Array[String] = ["Content-Type: application/json"]
	if include_session_headers and _session_token != "":
		headers.append("x-session-token:%s" % _session_token)

	var body := ""
	if body_obj != null:
		body = JSON.stringify(body_obj)

	# HTTPRequest ne peut gérer qu'un appel à la fois ; on attend sa complétion.
	var err = _http.request(url, headers, method, body)
	if err != OK:
		return { "ok": false, "error": "HTTPRequest error code: %s" % err }

	var result = await _http.request_completed
	# result: [result_code, response_code, response_headers, response_body]
	var result_code: int = result[0]
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return { "ok": false, "error": "HTTP result=%s code=%s" % [result_code, response_code] }

	var text := ""
	if response_body.size() > 0:
		text = response_body.get_string_from_utf8()

	var data: Variant = null
	if text != "":
		# Godot 4: JSON.parse_string renvoie Variant | null
		data = JSON.parse_string(text)
		if data == null:
			return { "ok": false, "error": "Réponse non-JSON: %s" % text }

	# Codes 2xx considérés comme OK
	if response_code >= 200 and response_code < 300:
		return { "ok": true, "data": data }
	else:
		var err_msg: String = ""
		if typeof(data) == TYPE_STRING:
			err_msg = data
		else:
			err_msg = JSON.stringify(data)

		return { "ok": false, "error": "HTTP %d: %s" % [response_code, err_msg] }

# === Interne : Persistance simple de l'identifiant joueur ===
func _save_player_identifier(pid: String) -> void:
	var f := FileAccess.open("user://LootLocker.data", FileAccess.WRITE)
	if f:
		f.store_string(pid)
		f.close()

func _load_player_identifier() -> String:
	var f := FileAccess.open("user://LootLocker.data", FileAccess.READ)
	if f == null:
		return ""
	var s := f.get_as_text()
	f.close()
	return s if s is String else ""
