extends BaseButton

@export var menu_to_open: PackedScene

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if menu_to_open:
		UIManager.open_menu(menu_to_open)
	else:
		print("OpenMenuButton: No menu scene assigned!")
