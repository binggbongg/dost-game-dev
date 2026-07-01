extends Control

@export_group("Music")
@export var menu_bgm: AudioStream 

# TextureRects for visuals
@onready var new_game_button: TextureRect = $Play/NewGame
@onready var continue_button: TextureRect = $Play/Continue

@export_group("Scene Navigation")
@export var lounge: PackedScene 
@export var setup: PackedScene 
@export var intro: PackedScene

@onready var play_button: TextureButton = $Play
@onready var settings_button: TextureButton = $Settings
@onready var audio_button: TextureButton = $Audio
@onready var audio_icon_on: TextureRect = $Audio/Audio_On
@onready var audio_icon_off: TextureRect = $Audio/Audio_On2
@onready var exit: TextureButton = $Exit

var next_scene: PackedScene 
var is_returning_player: bool = false

#func _ready():
	#if PlayerProfile.player_name != "Default Player":
		#next_scene = setup
		#new_game_button.visible = true
		#continue_button.visible = false
	#else:
		#next_scene = lounge
		#new_game_button.visible = false
		#continue_button.visible = true
#
	#new_game_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#continue_button.mouse_entered.connect(_on_button_hover) # Optional: pass hover to images
	#continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
#
	#if menu_bgm:
		#AudioManager.play_bgm(menu_bgm)
	#
	#play_button.pressed.connect(_on_play_pressed)
	#settings_button.pressed.connect(_on_settings_pressed)
	#audio_button.pressed.connect(_on_audio_pressed)
	#exit.pressed.connect(_on_exit_pressed)
	#play_button.mouse_entered.connect(_on_button_hover)
	#settings_button.mouse_entered.connect(_on_button_hover)
	#audio_button.mouse_entered.connect(_on_button_hover)

func _ready():
	new_game_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if menu_bgm:
		AudioManager.play_bgm(menu_bgm)
	
	settings_button.pressed.connect(_on_settings_pressed)
	audio_button.pressed.connect(_on_audio_pressed)
	exit.pressed.connect(_on_exit_pressed)
	
	play_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	audio_button.mouse_entered.connect(_on_button_hover)
	
	update_settings_button_state()
	
	# Find out if we are running an intro or continuing a run
	check_player_history()

func update_settings_button_state():
	if typeof(Talo) != TYPE_NIL and Talo.identity_check() == OK:
		print("MainMenu: Player is authenticated. Locking settings login menu entry.")
		settings_button.disabled = true
		settings_button.modulate = Color(0.4, 0.4, 0.4, 0.9) # Dim the gear icon visually
		
		# will add additional logic for the settings button if it used in another scene
	else:
		settings_button.disabled = false
		settings_button.modulate = Color(1, 1, 1, 1) # Full color opacity
		
		# Make sure the settings button pressed functionality is safely hooked up
		if not settings_button.pressed.is_connected(_on_settings_pressed):
			settings_button.pressed.connect(_on_settings_pressed)

func check_player_history() -> void:
	print("MainMenu: Contacting Talo to fetch account save metadata...")
	play_button.disabled = true
	
	Talo.saves.get_saves()
	await Talo.saves.saves_loaded
	
	if Talo.saves.latest != null:
		print("MainMenu: Save slot discovered! Configuring for CONTINUE.")
		is_returning_player = true
		next_scene = lounge
		
		new_game_button.visible = false
		continue_button.visible = true
	else:
		print("MainMenu: Fresh user account profile detected! Configuring for NEW GAME.")
		is_returning_player = false
		# Force routing through the Intro Cutscene. If it's missing, fall back to setup.
		next_scene = intro if intro != null else setup
		
		new_game_button.visible = true
		continue_button.visible = false
		
	# Connect the play button click now that the route destination is fully locked in
	play_button.disabled = false
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed():
	AudioManager.play_ui_sound("click")
	# Ensure the next_scene variable was actually set
	if not next_scene:
		print("next scene null -- from play")
	
	if is_returning_player:
		if typeof(SaveManager) != TYPE_NIL and SaveManager.has_method("sync_with_cloud"):
			await SaveManager.sync_with_cloud()
	else:
		PlayerProfile.player_name = "Default Player"
		PlayerProfile.selected_character = "None"
		PlayerProfile.max_unlocked_chapters = 1
		PlayerProfile.high_scores.clear()
	
	SceneTransition.change_scene(next_scene)

func _on_settings_pressed():
	AudioManager.play_ui_sound("click")
	
func _on_audio_pressed():
	AudioManager.play_ui_sound("click")
	AudioManager.toggle_mute()
	_update_audio_ui()

func _on_button_hover():
	AudioManager.play_ui_sound("hover")

func _update_audio_ui():
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	
	audio_icon_on.visible = !is_muted
	audio_icon_off.visible = is_muted

func _on_exit_pressed():
	AudioManager.play_ui_sound("click")
	await get_tree().create_timer(0.1).timeout 
	get_tree().quit()
