extends Control

@export var phase_number: int = 1

func _ready() -> void:
	if $CloseButton:
		$CloseButton.pressed.connect(_on_closed_pressed)
	
	if $PlayButton:
		$PlayButton.pressed.connect(_on_play_pressed)

func _on_closed_pressed():
	UIManager.close_menu()

func _on_play_pressed():
	print("directing to ", phase_number, ", level 1")
	PlayerProfile.current_phase = phase_number
	PlayerProfile.current_level = 1
	UIManager.close_menu()
	
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")
