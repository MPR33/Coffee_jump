extends Node

@export var doodle_packed: PackedScene
@export var coffee_packed: PackedScene
@export var doodle_music: PackedScene
@export var coffee_music: PackedScene

signal transition_state_changed(is_transitioning: bool)

var doodle_node: Node = null
var coffee_node: Node = null
var doodle_music_node: Node = null
var coffee_music_node: Node = null

var current_mode: int = GameManager.Mode.DOODLE
var first_coffee := true
var last_doodle_pos: Vector2 = Vector2.ZERO
var last_coffee_pos: Vector2 = Vector2.ZERO
var is_transitioning := false

func _ready() -> void:
	doodle_node = doodle_packed.instantiate()
	add_child(doodle_node)
	# Musique DOODLE au tout début
	_ensure_music_for(GameManager.Mode.DOODLE)
	_start_music_for(GameManager.Mode.DOODLE)

	GameManager.mode_changed.connect(_on_mode_changed)
	var start_str := "doodle" if GameManager.mode == GameManager.Mode.DOODLE else "coffee"
	load_mode(start_str)

func _on_mode_changed(new_mode: int) -> void:
	if is_transitioning:
		return
	var next := "doodle" if new_mode == GameManager.Mode.DOODLE else "coffee"
	transition_to(next)

func load_mode(mode_str: String) -> void:
	if mode_str == "doodle":
		if doodle_node == null:
			doodle_node = doodle_packed.instantiate()
			add_child(doodle_node)
			# La 1ʳᵉ fois seulement, instancie la musique et la lance
			_ensure_music_for(GameManager.Mode.DOODLE)
			_start_music_for(GameManager.Mode.DOODLE)
		_set_active(doodle_node, true)
		_set_active(coffee_node, false)
		# Pause la musique coffee, reprend doodle
		_pause_music_for(GameManager.Mode.COFFEE)
		_resume_music_for(GameManager.Mode.DOODLE)
		current_mode = GameManager.Mode.DOODLE
	else:
		if coffee_node == null:
			coffee_node = coffee_packed.instantiate()
			add_child(coffee_node)
			_ensure_music_for(GameManager.Mode.COFFEE)
			_start_music_for(GameManager.Mode.COFFEE)
		_set_active(coffee_node, true)
		_set_active(doodle_node, false)
		_pause_music_for(GameManager.Mode.DOODLE)
		_resume_music_for(GameManager.Mode.COFFEE)
		current_mode = GameManager.Mode.COFFEE

func transition_to(next_mode: String) -> void:
	is_transitioning = true
	emit_signal("transition_state_changed", true)
	var current_node := doodle_node if current_mode == GameManager.Mode.DOODLE else coffee_node

	# 1) geler + mémoriser position
	if current_node:
		current_node.process_mode = Node.PROCESS_MODE_DISABLED
		var player := _get_player(current_node, current_mode)
		if player:
			if current_mode == GameManager.Mode.DOODLE:
				last_doodle_pos = player.global_position
			else:
				last_coffee_pos = player.global_position

	# Met en PAUSE la musique du mode courant avant de basculer
	_pause_music_for(current_mode)

	await get_tree().create_timer(0.3).timeout

	# 2) charger/afficher prochain mode
	if next_mode == "doodle":
		if doodle_node == null:
			doodle_node = doodle_packed.instantiate()
			add_child(doodle_node)
			_ensure_music_for(GameManager.Mode.DOODLE)
			_start_music_for(GameManager.Mode.DOODLE) # première fois
		var p := _get_player(doodle_node, GameManager.Mode.DOODLE)
		if p and last_doodle_pos != Vector2.ZERO:
			p.global_position = last_doodle_pos

		_focus_camera(doodle_node)
		_set_active(doodle_node, true, true)
		_set_active(coffee_node, false)
		_force_update_score_ui()
		await get_tree().create_timer(0.5).timeout
		doodle_node.process_mode = Node.PROCESS_MODE_INHERIT
		current_mode = GameManager.Mode.DOODLE

		# Reprendre DOODLE, s'assurer que COFFEE reste en pause
		_resume_music_for(GameManager.Mode.DOODLE)
		_pause_music_for(GameManager.Mode.COFFEE)
	else:
		if coffee_node == null:
			coffee_node = coffee_packed.instantiate()
			add_child(coffee_node)
			_ensure_music_for(GameManager.Mode.COFFEE)
			_start_music_for(GameManager.Mode.COFFEE)
		var p2 := _get_player(coffee_node, GameManager.Mode.COFFEE)
		if p2:
			if first_coffee or last_coffee_pos == Vector2.ZERO:
				p2.global_position = Vector2(0, -200)
			else:
				p2.global_position = last_coffee_pos

		_focus_camera(coffee_node)
		_set_active(coffee_node, true, true)
		_set_active(doodle_node, false)
		_force_update_score_ui()
		await get_tree().create_timer(0.5).timeout
		coffee_node.process_mode = Node.PROCESS_MODE_INHERIT
		first_coffee = false
		current_mode = GameManager.Mode.COFFEE

		_resume_music_for(GameManager.Mode.COFFEE)
		_pause_music_for(GameManager.Mode.DOODLE)

	is_transitioning = false
	emit_signal("transition_state_changed", false)

# ------------------ MUSIQUE (helpers très simples) ------------------

func _ensure_music_for(mode: int) -> void:
	if mode == GameManager.Mode.DOODLE:
		if doodle_music_node == null and doodle_music:
			doodle_music_node = doodle_music.instantiate()
			add_child(doodle_music_node)
			_fix_2d_music(doodle_music_node)
	else:
		if coffee_music_node == null and coffee_music:
			coffee_music_node = coffee_music.instantiate()
			add_child(coffee_music_node)
			_fix_2d_music(coffee_music_node)

func _fix_2d_music(n: Node) -> void:
	if n is AudioStreamPlayer2D:
		var p := n as AudioStreamPlayer2D
		p.attenuation = 0.0          # => aucune atténuation avec la distance
		p.max_distance = 1e12        # sécurité
		# Optionnel : le “souder” à la caméra courante pour être toujours à 0 de distance
		p.top_level = true
		var cam := get_viewport().get_camera_2d()
		if cam:
			p.global_position = cam.global_position


func _resume_music_for(mode: int) -> void:
	var p := _music_player(mode)
	if p == null:
		return
	# Si jamais elle n’a pas encore joué, play(); sinon dé-pauser
	if not p.playing:
		p.play()
	else:
		p.stream_paused = false

func _pause_music_for(mode: int) -> void:
	var p := _music_player(mode)
	if p:
		p.stream_paused = true

func _start_music_for(mode: int) -> void:
	var p := _music_player(mode)
	if p and not p.playing:
		p.play()

func _music_player(mode: int) -> Node:
	var n := doodle_music_node if mode == GameManager.Mode.DOODLE else coffee_music_node
	if n == null:
		return null
	# Le root de ta PackedScene peut être AudioStreamPlayer **ou** AudioStreamPlayer2D.
	# On le retourne tel quel : les deux ont .play(), .playing, .stream_paused.
	return n

# ------------------ (le reste inchangé) ------------------

func _set_active(node: Node, on: bool, frozen: bool=false) -> void:
	if node == null: return
	node.process_mode = Node.PROCESS_MODE_DISABLED if (not on or frozen) else Node.PROCESS_MODE_INHERIT
	_set_canvasitems_visible_recursive(node, on)
	_set_canvaslayers_visible(node, on)
	_set_cameras_active(node, on)

func _set_canvasitems_visible_recursive(n: Node, on: bool) -> void:
	if n is CanvasItem:
		(n as CanvasItem).visible = on
	for c in n.get_children():
		_set_canvasitems_visible_recursive(c, on)

func _set_canvaslayers_visible(n: Node, on: bool) -> void:
	for c in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = on
		_set_canvaslayers_visible(c, on)

func _set_cameras_active(n: Node, active: bool) -> void:
	for c in n.get_children():
		if c is Camera2D:
			var cam := c as Camera2D
			cam.enabled = active
			if not active and cam.is_current():
				cam.clear_current()
		_set_cameras_active(c, active)

func _get_player(mode_node: Node, _mode_id: int) -> Node2D:
	return mode_node.get_node_or_null("Player")

func _focus_camera(mode_node: Node) -> void:
	var cam := mode_node.get_node_or_null("camera") as Camera2D
	if cam == null:
		cam = _find_camera(mode_node)
	if cam:
		if doodle_node: _set_cameras_active(doodle_node, false)
		if coffee_node: _set_cameras_active(coffee_node, false)
		cam.enabled = true
		cam.make_current()

func _find_camera(n: Node) -> Camera2D:
	if n is Camera2D:
		return n as Camera2D
	for c in n.get_children():
		var f := _find_camera(c)
		if f: return f
	return null

func _force_update_score_ui() -> void:
	var label := get_node_or_null("camera/CanvasLayer/score") as Label
	if label:
		label.text = str(int(-GameManager.score_sugar + GameManager.score_coffee))
