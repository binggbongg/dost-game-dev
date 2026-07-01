extends Node2D

@onready var cam = $Camera2D
@onready var map = $Map

var is_dragging = false

func _ready():
	# 1. Wait a frame to make sure Godot has calculated the Map size correctly
	await get_tree().process_frame
	
	var viewport_size = get_viewport_rect().size
	var map_size = map.get_global_rect().size

	# 2. Set the starting X to the middle of the map
	cam.position.x = map_size.x / 2
	
	# 3. Set the starting Y to the very BOTTOM of the map
	# Logic: Total map height minus half the screen height
	cam.position.y = map_size.y - (viewport_size.y / 2)
	
	# 4. Lock it in immediately so it doesn't show gray
	limit_camera_view()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
	if event is InputEventMouseMotion and is_dragging:
		# 1. Apply the movement
		cam.position -= event.relative / cam.zoom
		
		# 2. Immediately clamp the position so it NEVER shows gray
		limit_camera_view()

func limit_camera_view():
	var viewport_size = get_viewport_rect().size
	var map_size = map.get_global_rect().size
	
	# Calculate how much of the map the camera is allowed to see
	# We clamp the CENTER of the camera.
	var min_x = (viewport_size.x / 2) / cam.zoom.x
	var min_y = (viewport_size.y / 2) / cam.zoom.y
	
	var max_x = map_size.x - min_x
	var max_y = map_size.y - min_y
	
	# If the map is smaller than the screen, stay at center
	if map_size.x < viewport_size.x:
		cam.position.x = map_size.x / 2
	else:
		cam.position.x = clamp(cam.position.x, min_x, max_x)
		
	if map_size.y < viewport_size.y:
		cam.position.y = map_size.y / 2
	else:
		cam.position.y = clamp(cam.position.y, min_y, max_y)
