extends TextureButton

@export var pause_screen: PackedScene

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed():
	if UIManager.current_menu == null and pause_screen:
		UIManager.open_menu(pause_screen)
	else:
		print("cannot open pause screen. no scene attached -- from pausebutton")
