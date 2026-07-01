extends TextureButton
@export var next_scene: PackedScene

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if next_scene:
		AudioManager.play_ui_sound("click")
		SceneTransition.change_scene(next_scene)
	else:
		print("OpenMenuButton: No menu scene assigned!")
