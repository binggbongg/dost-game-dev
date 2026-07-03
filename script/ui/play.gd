extends Control

@export_group("Music")
@export var menu_bgm: AudioStream 

# TextureRects for visuals
#@onready var new_game_button: TextureRect = $Play/NewGame
#@onready var continue_button: TextureRect = $Play/Continue

@export_group("Scene Navigation")
@export var lounge: PackedScene 
@export var setup: PackedScene 
@export var intro: PackedScene

#@onready var play_button: TextureButton = $Play
@onready var settings_button: TextureButton = $Settings
@onready var audio_button: TextureButton = $Audio
@onready var audio_icon_on: TextureRect = $Audio/Audio_On
@onready var audio_icon_off: TextureRect = $Audio/Audio_On2
@onready var exit: TextureButton = $Exit

@onready var new_game_btn: TextureButton = $NewGameButton
@onready var continue_btn: TextureButton = $ContinueButton

var next_scene: PackedScene 
var is_returning_player: bool = false

func _ready():
	if menu_bgm:
		AudioManager.play_bgm(menu_bgm)
	
	settings_button.pressed.connect(_on_settings_pressed)
	audio_button.pressed.connect(_on_audio_pressed)
	exit.pressed.connect(_on_exit_pressed)
	
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	
	new_game_btn.mouse_entered.connect(_on_button_hover)
	continue_btn.mouse_entered.connect(_on_button_hover)
	
	settings_button.mouse_entered.connect(_on_button_hover)
	audio_button.mouse_entered.connect(_on_button_hover)
	
	update_settings_button_state()
	
	# Find out if we are running an intro or continuing a run
	check_player_history()

func update_settings_button_state():
	# 🌟 THE FIX: Pass 'false' so Talo returns a status code instead of throwing a loud error!
	if typeof(Talo) != TYPE_NIL and Talo.identity_check(false) == OK:
		print("MainMenu: Player is authenticated. Locking settings login menu entry.")
		settings_button.disabled = true
		settings_button.modulate = Color(0.4, 0.4, 0.4, 0.9)
	else:
		settings_button.disabled = false
		settings_button.modulate = Color(1, 1, 1, 1)
		
		if not settings_button.pressed.is_connected(_on_settings_pressed):
			settings_button.pressed.connect(_on_settings_pressed)

func check_player_history() -> void:
	print("MainMenu: Contacting Talo to fetch account save metadata...")
	
	new_game_btn.disabled = true
	continue_btn.disabled = true
	
	if typeof(Talo) == TYPE_NIL or Talo.identity_check(false) != OK:
		print("MainMenu: Player not authenticated. Displaying locked state.")
		is_returning_player = false
		
		new_game_btn.visible = true
		new_game_btn.disabled = true
		new_game_btn.modulate = Color(0.4, 0.4, 0.4, 0.9)
		
		continue_btn.visible = true
		continue_btn.disabled = true
		continue_btn.modulate = Color(0.4, 0.4, 0.4, 0.9)
		return

	new_game_btn.modulate = Color(1, 1, 1, 1)
	continue_btn.modulate = Color(1, 1, 1, 1)

	Talo.saves.get_saves()
	await Talo.saves.saves_loaded
	
	if Talo.saves.latest != null and PlayerProfile.is_profile_initialized:
		print("MainMenu: Initialized save slot discovered! Configuring for CONTINUE.")
		is_returning_player = true
		next_scene = lounge
		
		new_game_btn.disabled = false
		new_game_btn.visible = true
		continue_btn.visible = true
		continue_btn.disabled = false
		
	else:
		print("MainMenu: Fresh account placeholder or uninitialized profile detected! Configuring for NEW GAME.")
		is_returning_player = false
		next_scene = intro if intro != null else setup
		
		new_game_btn.visible = true
		new_game_btn.disabled = false
		continue_btn.disabled = true
		continue_btn.modulate = Color(0.4, 0.4, 0.4, 0.9)

func _on_new_game_pressed():
	AudioManager.play_ui_sound("click")
	if not next_scene:
		print("no next scene for new game -- play")
		return
	
	PlayerProfile.player_name = "Default Player"
	PlayerProfile.selected_character = "None"
	PlayerProfile.max_unlocked_chapters = 1
	PlayerProfile.high_scores.clear()
	
	SceneTransition.change_scene(next_scene)

func _on_continue_pressed():
	AudioManager.play_ui_sound("click")
	if not next_scene:
		print("no next scene for continue game --play")
		return
	
	if typeof(SaveManager) != TYPE_NIL and SaveManager.has_method("sync_with_cloud"):
		await SaveManager.sync_with_cloud()
	
	SceneTransition.change_scene(next_scene) 

func _on_settings_pressed():
	AudioManager.play_ui_sound("click")
	UIManager.open_menu(setup)

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
