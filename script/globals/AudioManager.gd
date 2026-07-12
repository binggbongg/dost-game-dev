extends Node

# --- VARIABLES ---
@onready var bgm_player1 = AudioStreamPlayer.new()
@onready var bgm_player2 = AudioStreamPlayer.new()
@onready var sfx_players: Array = []

var active_bgm_player: AudioStreamPlayer
var library = preload("res://data/SoundData/GameSounds.tres") 
var current_bgm_path: String = ""

func play_sound_from_path(file_path: String, is_bgm: bool = false, volume_adjust: float = 0.0) -> void:
	if not ResourceLoader.exists(file_path):
		print("AudioManager Error: Audio file path does not exist! -> ", file_path)
		return
		
	var stream = load(file_path) as AudioStream
	if not stream:
		print("AudioManager Error: Failed to load file as AudioStream -> ", file_path)
		return
		
	if is_bgm:
		play_bgm(stream)
		# Set volume adjustment target safely
		active_bgm_player.volume_db = volume_adjust 
	else:
		for p in sfx_players:
			if not p.playing:
				p.stream = stream
				p.pitch_scale = randf_range(0.95, 1.05)
				p.volume_db = volume_adjust 
				p.play()
				return


# 3. Clear the path if you ever explicitly stop the music
func stop_bgm(fade_duration: float = 1.0):
	current_bgm_path = "" # Clear path tracker
	var tween = create_tween()
	tween.tween_property(active_bgm_player, "volume_db", -80, fade_duration)
	tween.tween_callback(active_bgm_player.stop)
	
# --- INITIALIZATION ---
func _ready():
	# Setup BGM players
	add_child(bgm_player1)
	add_child(bgm_player2)
	bgm_player1.bus = "Music"
	bgm_player2.bus = "Music"
	active_bgm_player = bgm_player1
	
	# Create a pool of 15 SFX players
	for i in 15:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)

# --- THE "PLAY BY NAME" FUNCTION ---
func play_ui_sound(sound_name: String):
	if library == null:
		print("AudioManager Error: Library (GameSounds.tres) not found!")
		return

	match sound_name:
		"click": play_sfx(library.click)
		"hover": play_sfx(library.hover)
		"flip": play_sfx(library.page_flip)
		"shuffle": play_sfx(library.card_shuffle)
		"drag": play_sfx(library.card_drag)
		"drop": play_sfx(library.card_drop)
		_: print("AudioManager: Sound name '", sound_name, "' not found in match list.")

# --- CORE SFX LOGIC ---
func play_sfx(stream: AudioStream, pitch_variance: float = 0.1):
	if stream == null: return 
	
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
			p.volume_db = 0.0 # Reset to default baseline
			p.play()
			return

func play_bgm(stream: AudioStream, fade_duration: float = 1.0):
	if stream == null: return 
	
	# FIX: Only return early if the stream matches AND the player is actually playing.
	# If it's stopped (from the scene transition), we need to kickstart it again!
	if active_bgm_player.stream == stream and active_bgm_player.playing: 
		return 
	
	var old_player = active_bgm_player
	active_bgm_player = bgm_player2 if active_bgm_player == bgm_player1 else bgm_player1
	
	active_bgm_player.stream = stream
	active_bgm_player.volume_db = -80 
	active_bgm_player.play()
	
	var tween = create_tween()
	tween.tween_property(active_bgm_player, "volume_db", 0, fade_duration)
	tween.parallel().tween_property(old_player, "volume_db", -80, fade_duration)
	tween.tween_callback(old_player.stop)




# --- MASTER MUTE ---
func toggle_mute():
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, !is_muted)
	return !is_muted
