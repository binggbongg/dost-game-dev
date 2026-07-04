extends MenuBase

func _ready():
	super._ready()
	get_tree().paused = true
	$PlayButton.pressed.connect(_on_resume_pressed)
	$ResetButon.pressed.connect(_on_restart_pressed)
	$ExitButton.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	get_tree().paused = false
	UIManager.close_menu()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	UIManager.close_menu()

func _on_quit_pressed():
	print("quitting game")
	UIManager.close_menu()
	get_tree().change_scene_to_file("res://scenes/menus/lounge.tscn")
	# will transfer back to the map scene.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
