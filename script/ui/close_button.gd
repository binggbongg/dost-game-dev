extends TextureButton

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed():
	UIManager.close_menu()
