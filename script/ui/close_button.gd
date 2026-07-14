extends TextureButton

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed():
	get_tree().paused = false
	UIManager.close_menu()
