extends TextureButton

@export var scene_to_open: PackedScene

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _process(_delta: float) -> void:
	if UIManager.current_menu != null:
		self.disabled = true
		self_modulate = Color(0.5, 0.5, 0.5, 0.5)
	else:
		self.disabled = false
		self_modulate = Color(1, 1, 1, 1)

func _on_pressed():
	if scene_to_open:
		get_tree().paused = true
		UIManager.open_menu(scene_to_open)
	else:
		print("could not find scene to open -- spellbook button")
