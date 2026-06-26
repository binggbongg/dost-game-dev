extends Node

signal menu_opened(menu_name: String)
signal menu_closed

var current_menu: Control = null
var ui_layer: CanvasLayer = null

func _ready():
	setup_ui_layer()

func setup_ui_layer():
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100 # High number so it stays on top
	add_child(ui_layer)

func open_menu(menu_scene: PackedScene):
	if current_menu != null:
		close_menu()
	
	current_menu = menu_scene.instantiate()
	ui_layer.add_child(current_menu)
	
	menu_opened.emit(current_menu.name)
	print("UIManager: Opened ", current_menu.name)

func close_menu():
	if current_menu != null:
		current_menu.queue_free()
		current_menu = null
		menu_closed.emit()
		print("UIManager: Menu closed")

func toggle_menu(menu_scene: PackedScene):
	if current_menu != null:
		close_menu()
	else:
		open_menu(menu_scene)

func _input(event):
	if event.is_action_pressed("ui_cancel"): 
		if current_menu != null:
			close_menu()
