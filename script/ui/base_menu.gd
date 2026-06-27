extends Control
class_name MenuBase
func _ready():
	var close_btn = get_node_or_null("CloseButton") 
	close_btn.pressed.connect(_on_close_pressed)
		

func _on_close_pressed():
	print("MenuBase: Close button clicked!")
	UIManager.close_menu()
