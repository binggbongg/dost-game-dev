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
	
	if PlayerProfile.has_method("reset_run_counter"):
		PlayerProfile.reset_run_counter()
	
	if PlayerStats.has_method("reset_health"):
		PlayerStats.reset_health()
	
	UIManager.close_menu()
	
	var dynamic_res_path = "res://data/Levels/level_%d-1.tres" % phase_number
	if ResourceLoader.exists(dynamic_res_path):
		PlayerProfile.next_level_resource = load(dynamic_res_path)
		get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")
	else:
		print("could not find resource file --preview phase")
