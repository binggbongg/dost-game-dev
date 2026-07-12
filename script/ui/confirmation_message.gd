extends Control

@onready var yes_label = $YesLabel
@onready var no_label = $NoLabel

func _ready() -> void:
	if yes_label:
		yes_label.gui_input.connect(_on_yes_gui_input)
	
	if no_label:
		no_label.gui_input.connect(_on_no_gui_input)

func _on_yes_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		quit_game()

func _on_no_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		resume_game()

func quit_game():
	print("used the quit method")
	UIManager.close_menu()
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://scenes/menus/lounge.tscn")

func resume_game():
	print("used the resume method")
	get_tree().paused = false
	UIManager.close_menu()
