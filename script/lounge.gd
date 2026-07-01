extends Node2D

@onready var cam = $Camera2D
@onready var map = $Map

# --- UPDATED PATHS (Option 1) ---
# Since you moved everything into 'Content', we must update the paths
@onready var buttons_container = $Buttons/Content
@onready var player_name_label: Label = $Buttons/Content/PlayerName

# Tutorial Nodes
@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var arrow = $TutorialLayer/arrow_up

var is_dragging = false
var tutorial_active = false

func _ready():
	# 1. SETUP CAMERA (Start at BOTTOM LEFT)
	await get_tree().process_frame
	var viewport_size = get_viewport_rect().size
	var map_size = map.get_global_rect().size
	
	# To start at BOTTOM LEFT:
	# X is just half the screen width (leftmost clamped position)
	cam.position.x = (viewport_size.x / 2) / cam.zoom.x
	# Y is the map height minus half the screen height
	cam.position.y = map_size.y - ((viewport_size.y / 2) / cam.zoom.y)
	
	limit_camera_view()
	
	# 2. UPDATE UI
	if PlayerProfile.player_name != "Default Player":
		player_name_label.text = PlayerProfile.player_name
	
	# 3. START TUTORIAL IF NEW PLAYER
	if not PlayerProfile.tutorial_steps_completed.get("lounge_tour", false):
		start_lounge_tour()
	else:
		dimmer.hide()
		arrow.hide()

func _unhandled_input(event):
	if tutorial_active: return 
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
	if event is InputEventMouseMotion and is_dragging:
		cam.position -= event.relative / cam.zoom
		limit_camera_view()

# --- TUTORIAL FLOW ---

func start_lounge_tour():
	tutorial_active = true
	dimmer.show()
	
	# We pass the nodes that are now inside 'Content'
	await highlight_and_talk(buttons_container.get_node("CharacterSpotlight"), "res://data/StoryData/Tutorial/characterspotlight.tres")
	
	# Step 2: Coins (Top Right)
	# await highlight_and_talk(buttons_container.get_node("CoinDisplay"), "res://data/StoryData/Tutorial/coins.tres")
	
	# ... Add other steps here using the same buttons_container.get_node() format ...
	
	reset_highlights()
	dimmer.hide()
	arrow.hide()
	tutorial_active = false
	PlayerProfile.tutorial_steps_completed["lounge_tour"] = true

func highlight_and_talk(node: Control, data_path: String):
	reset_highlights()
	
	var screen_h = get_viewport_rect().size.y
	var is_bottom_half = node.global_position.y > (screen_h / 2)
	
	arrow.show()
	if is_bottom_half:
		arrow.global_position = node.global_position + Vector2(node.size.x / 2, -40)
		arrow.rotation_degrees = 180 
	else:
		arrow.global_position = node.global_position + Vector2(node.size.x / 2, node.size.y + 40)
		arrow.rotation_degrees = 0
	
	node.z_index = 101
	node.modulate = Color(1.5, 1.5, 1.5)
	buttons_container.modulate = Color(0.4, 0.4, 0.4)
	
	var data = load(data_path)
	StoryManager.play(data)
	if StoryManager.ui:
		StoryManager.ui.set_dialogue_position(!is_bottom_half)
	
	await StoryManager.ui.sequence_finished

func reset_highlights():
	buttons_container.modulate = Color.WHITE
	for child in buttons_container.get_children():
		if child is Control:
			child.z_index = 0
			child.modulate = Color.WHITE

# --- CAMERA CLAMPING ---

func limit_camera_view():
	var viewport_size = get_viewport_rect().size
	var map_size = map.get_global_rect().size
	var min_x = (viewport_size.x / 2) / cam.zoom.x
	var min_y = (viewport_size.y / 2) / cam.zoom.y
	var max_x = map_size.x - min_x
	var max_y = map_size.y - min_y
	
	cam.position.x = clamp(cam.position.x, min_x, max_x)
	cam.position.y = clamp(cam.position.y, min_y, max_y)
