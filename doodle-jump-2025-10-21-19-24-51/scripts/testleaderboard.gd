extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func upload_score(player_name: String, score: int) -> void:
	var headers = ["Content-Type: application/json"]
	var body = {
		"player": player_name,
		"score": score
	}
	%GameOver/AddScoreHTTPRequest.request("https://echoes.maoune.fr/score/add/", headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func get_scores() -> void:
	%Leaderboard/GetScoreHTTPRequest.request("https://coffee.maoune.fr/score/list")

func _on_leaderboard_http_request_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var scores = JSON.parse_string(body.get_string_from_utf8())
		var current_label_index = 1
		for score in scores:
			var player_name = score["player"]
			var player_score = score["score"]
			var new_score = %Leaderboard/VBoxContainer/Scores.get_node("Score" + str(current_label_index))
			new_score.text = player_name + " - " + str(player_score)
			current_label_index += 1
		for i in range(current_label_index, 11):
			var new_score = %Leaderboard/VBoxContainer/Scores.get_node("Score" + str(i))
			new_score.text = "Empty"
	else:
		print("Error: " + str(response_code))


func _on_gameover_http_request_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		%GameOver/VBoxContainer/SendingStatus.text = "Score sent successfully!"
	else:
		%GameOver/VBoxContainer/SendingStatus.text = "Error: " + str(response_code)
		print("Error: " + str(response_code))
