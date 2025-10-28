extends Control

@onready var highscore: Label = $highscore
@onready var title: TextureRect =$"main/game-title"
@onready var music: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var anim:= $anim as AnimatedSprite2D

const TITLE_MUSIC: AudioStream = preload("res://assets/sounds/Hikari E [8 bit cover] - One Piece OP 3.wav")

# -------- Réglages détection "sons aigus qui se détachent" ----------
@export var highs_low_hz: float = 1500.0      # ← mélodie
@export var highs_high_hz: float = 5000.0     # ← mélodie
@export var wide_low_hz: float = 200.0        # énergie globale utile
@export var wide_high_hz: float = 5000.0      # énergie globale (mais sans les extrêmes)

# Enveloppes (lissage rapide vs lent sur les aigus)
@export var fast_rate: float = 28         # plus haut = plus nerveux (30–40)
@export var slow_rate: float = 6.0            # plus haut = suit plus vite le fond (5–10)

# Seuils / anti-spam
@export var contrast_threshold: float = 0.08  # 0.25–0.5 ; plus bas = plus sensible
@export var refractory_sec: float = 0.01      # délai mini entre deux bounces

# -------- Bounce visuel ----------
@export var punch_base: float = 0.22          # amplitude de base
@export var punch_gain: float = 0.35          # bonus amplitude proportionnel au pic
@export var punch_max_extra: float = 0.28     # plafond du bonus
@export var up_time: float = 0.07
@export var down_time: float = 0.18
@export var min_scale: float = 0.92
@export var max_scale: float = 1.60

# Internes
var analyzer_instance: AudioEffectSpectrumAnalyzerInstance
var base_scale := Vector2.ONE
var last_trigger_t := 0.0
var fast_env := 0.0
var slow_env := 0.0
var brightness_env := 0.1  # moyenne glissante de la "brillance" (proportion d'aigus)

func _ready() -> void:
	# ---- tes fonctionnalités existantes ----

	highscore.text = "Highscore : " + str(GameManager.highscore)
	add_child(music)
	music.bus = "Master"
	music.stream = TITLE_MUSIC
	music.volume_db = 0.0
	music.play()
	# ---- initialisation visuelle & audio ----
	set_process(true)
	#pause_mode = Node.PAUSE_MODE_PROCESS

	if title == null:
		push_error("Node titre introuvable (attendu: $main/game-title).")
		return
	base_scale = title.scale
	await get_tree().process_frame
	title.pivot_offset = title.size * 0.5

	var bus_idx := AudioServer.get_bus_index(music.bus)
	if bus_idx < 0:
		push_error("Bus '%s' introuvable." % music.bus)
		return
	_ensure_spectrum_on_bus(bus_idx)
	analyzer_instance = _get_spectrum_instance(bus_idx)
	if analyzer_instance == null:
		push_error("Impossible d'obtenir l'instance Spectrum Analyzer.")
		return

	await get_tree().process_frame
	last_trigger_t = Time.get_ticks_msec() / 1000.0
	if GameManager.retry:
		_on_startbtn_pressed()

func _process(delta: float) -> void:
	if analyzer_instance == null or title == null:
		return

	# 1) Énergies
	var e_high := analyzer_instance.get_magnitude_for_frequency_range(highs_low_hz, highs_high_hz).length()
	var e_wide := analyzer_instance.get_magnitude_for_frequency_range(wide_low_hz, wide_high_hz).length()
	var brightness := 0.0
	if e_wide > 1e-6:
		brightness = e_high / e_wide  # proportion d'aigus dans le mix

	# 2) Enveloppes rapide/lente sur les aigus
	fast_env = lerp(fast_env, e_high, clamp(delta * fast_rate, 0.0, 1.0))
	slow_env = lerp(slow_env, e_high, clamp(delta * slow_rate, 0.0, 1.0))
	brightness_env = lerp(brightness_env, brightness, clamp(delta * 2.0, 0.0, 1.0))

	# 3) Score de "saillance" (pic aigu qui se détache du fond)
	var contrast := 0.0
	if slow_env > 1e-6:
		contrast = (fast_env - slow_env) / slow_env  # variation relative
	# pondérer par la brillance par rapport à sa moyenne (evite les faux pics quand tout est mat)
	var bright_boost :float= clamp(brightness / max(brightness_env, 1e-6), 0.0, 3.0)
	var score := contrast * (0.5 + 0.5 * bright_boost)  # mix simple

	# 4) Déclenchement avec réfractaire
	var now := Time.get_ticks_msec() / 1000.0
	if score > contrast_threshold and (now - last_trigger_t) >= refractory_sec:
		var extra :float= clamp(score * punch_gain, 0.0, punch_max_extra)
		_trigger_bounce(punch_base + extra)
		last_trigger_t = now

	# 5) Bornes de sécurité
	title.scale = Vector2(
		clamp(title.scale.x, min_scale, max_scale),
		clamp(title.scale.y, min_scale, max_scale)
	)

# -------------------------
# Bounce visuel
# -------------------------
func _trigger_bounce(amount: float) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(title, "scale", base_scale * (1.0 + amount), up_time)
	t.tween_property(title, "scale", base_scale, down_time)

# -------------------------
# Utilitaires spectre
# -------------------------
func _ensure_spectrum_on_bus(bus_idx: int) -> void:
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectSpectrumAnalyzer:
			return
	var eff := AudioEffectSpectrumAnalyzer.new()
	# eff.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024  # optionnel: meilleure résolution
	AudioServer.add_bus_effect(bus_idx, eff, 0)

func _get_spectrum_instance(bus_idx: int) -> AudioEffectSpectrumAnalyzerInstance:
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectSpectrumAnalyzer:
			return AudioServer.get_bus_effect_instance(bus_idx, i)
	return null

# -----------------------------
# Tes fonctions existantes
# -----------------------------
func _input(event: InputEvent) -> void: # permet de lancer le jeu avec espace
	if event.is_action_pressed("start_game") and not GameManager.game_started:
		_on_startbtn_pressed()

func _on_quitbtn_pressed() -> void:
	get_tree().quit()

func _on_startbtn_pressed():
	if GameManager.block_input:
		return
	GameManager.block_input = true
	anim.play("default")
	var timer := get_tree().create_timer(3.3)
	await timer.timeout
	GameManager.reset_game_state()
	GameManager.score_sugar = 0
	GameManager.score_coffee = 0
	transitioon.change_scene("res://main.tscn", Vector2(90,200))
	
