extends Control
class_name MenuBase
func _ready():
	var close_btn = get_node_or_null("CloseButton") 
	
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	else:
		print("MenuBase: No generic 'CloseButton' found in " + name + ". Skipping auto-connect.")
		

func _on_close_pressed():
	print("MenuBase: Close button clicked!")
	UIManager.close_menu()
