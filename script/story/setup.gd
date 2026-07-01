extends Control

# --- EXPORTS ---
@export var lounge_scene: PackedScene # Drag your Lounge.tscn here

# --- ONREADY NODES (Matched to your screenshot) ---
@onready var character_group = $Character
@onready var name_group = $Name

@onready var boy_button = $Character/Boy/BoyButton
@onready var girl_button = $Character/Girl/GirlButton # Assuming the button name is the same

@onready var input_username = $Name/InputUsername
@onready var submit_button = $Name/Sunmit # Matched your 'Sunmit' typo from tree

# --- INTERNAL VARIABLES ---
var chosen_character_id: String = ""

func _ready():
	character_group.show()
	name_group.hide()
	boy_button.pressed.connect(_on_character_selected.bind("Boy"))
	girl_button.pressed.connect(_on_character_selected.bind("Girl"))
	submit_button.pressed.connect(_on_submit_pressed)
	input_username.text_submitted.connect(func(_text): _on_submit_pressed())
func _on_character_selected(char_id: String):
	AudioManager.play_ui_sound("click")
	
	chosen_character_id = char_id
	print("Character selected: ", chosen_character_id)
	
	character_group.hide()
	name_group.show()
	input_username.grab_focus()
	

func _on_submit_pressed():
	var entered_name = input_username.text.strip_edges()
	
	if entered_name == "":
		print("Please enter a name!")
		return
	
	AudioManager.play_ui_sound("click")
	
	PlayerProfile.initialize_profile(entered_name, chosen_character_id)
	
	if lounge_scene:
		SceneTransition.change_scene(lounge_scene)
	else:
		print("Error: No lounge scene assigned in Setup Inspector!")
