extends Control

@export_group("Music")
@export var menu_bgm: AudioStream 

# TextureRects for visuals
@onready var new_game_button: TextureRect = $Play/NewGame
@onready var continue_button: TextureRect = $Play/Continue

@export_group("Scene Navigation")
@export var lounge: PackedScene 
@export var setup: PackedScene 

@onready var play_button: TextureButton = $Play
@onready var settings_button: TextureButton = $Settings
@onready var audio_button: TextureButton = $Audio
@onready var audio_icon_on: TextureRect = $Audio/Audio_On
@onready var audio_icon_off: TextureRect = $Audio/Audio_On2
@onready var exit: TextureButton = $Exit

var next_scene: PackedScene 

func _ready():
	if PlayerProfile.player_name == "Default Player":
		next_scene = setup
		new_game_button.visible = true
		continue_button.visible = false
	else:
		next_scene = lounge
		new_game_button.visible = false
		continue_button.visible = true

	new_game_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.mouse_entered.connect(_on_button_hover) # Optional: pass hover to images
	continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if menu_bgm:
		AudioManager.play_bgm(menu_bgm)
	
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	audio_button.pressed.connect(_on_audio_pressed)
	exit.pressed.connect(_on_exit_pressed)
	play_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	audio_button.mouse_entered.connect(_on_button_hover)

func _on_play_pressed():
	AudioManager.play_ui_sound("click")
	# Ensure the next_scene variable was actually set
	if next_scene:
		SceneTransition.change_scene(next_scene)
	else:
		print("Error: next_scene is null! Check Inspector assignments.")

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
