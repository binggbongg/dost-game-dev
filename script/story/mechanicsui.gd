# MechanicsUI.gd
extends CanvasLayer

signal finished

@onready var panel = $MechanicsBox/MechanicsPanel
@onready var label_text = $MechanicsBox/MechanicsPanel/TextLabel
@onready var label_name = $MechanicsBox/MechanicsPanel/NameLabel
@onready var dimmer = $Dimmer 
@onready var highlight_layer = $HighlightLayer/Control
var is_active = false
var current_data: StoryData
var line_index = 0
var group_center := Vector2.ZERO
var group_size := Vector2.ZERO

func _ready():
	hide_everything()

func hide_everything():
	visible = false
	dimmer.hide()
	panel.hide()
	is_active = false

func start_tutorial(data: StoryData, target_node: CanvasItem = null):
	current_data = data
	line_index = 0
	label_name.text = data.character_name
	
	if target_node:
		if target_node.name == "ChapterOne":
			panel.global_position = Vector2(700, 650) 
		else:
			await position_box(target_node)
	
	visible = true
	dimmer.show() 
	panel.show()
	is_active = true
	next_line()
func position_box(target: CanvasItem):
	await get_tree().process_frame

	var target_pos: Vector2
	var target_size: Vector2

	if target is Control:
		var t_rect = target.get_global_rect()
		target_pos = t_rect.position
		target_size = t_rect.size

	elif target is Node2D:
		target_pos = target.global_position
		target_size = Vector2(100, 100) # Adjust as needed

	else:
		return

	var screen = get_viewport().get_visible_rect().size

	var margin := 20.0
	var spacing := 30.0

	var pos = Vector2(
		target_pos.x + target_size.x / 2.0 - panel.size.x / 2.0,
		0
	)

	var below_y = target_pos.y + target_size.y + spacing
	var above_y = target_pos.y - panel.size.y - spacing

	if below_y + panel.size.y <= screen.y - margin:
		pos.y = below_y
	elif above_y >= margin:
		pos.y = above_y
	else:
		pos.y = margin

	pos.x = clamp(
		pos.x,
		margin,
		screen.x - panel.size.x - margin
	)

	panel.global_position = pos

var last_start_time := 0
var input_delay_ms := 300 # 0.3 seconds

func start_group_tutorial(data: StoryData, targets: Array):
	print("UI: Starting group tutorial...")
	current_data = data
	line_index = 0
	label_name.text = data.character_name
	
	# Mark the time we started
	last_start_time = Time.get_ticks_msec()

	# ... (Keep your min_pos / max_pos logic here) ...
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for target in targets:
		if !is_instance_valid(target): continue
		var rect: Rect2
		if target is Control: rect = target.get_global_rect()
		elif target is Node2D:
			rect = Rect2(target.global_position - Vector2(60, 80), Vector2(120, 160))
		min_pos.x = min(min_pos.x, rect.position.x)
		min_pos.y = min(min_pos.y, rect.position.y)
		max_pos.x = max(max_pos.x, rect.end.x)
		max_pos.y = max(max_pos.y, rect.end.y)
	
	group_center = (min_pos + max_pos) / 2.0
	group_size = max_pos - min_pos
	
	position_group_box()
	set_group_spotlight()
	
	visible = true
	dimmer.show()
	panel.show()
	is_active = true
	
	next_line()

func _input(event):
	if not is_active: return
	
	# If we just started, ignore clicks for a split second to prevent skipping
	if Time.get_ticks_msec() - last_start_time < input_delay_ms:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		print("UI: Click detected, advancing line...")
		if label_text.visible_ratio < 1.0:
			label_text.visible_ratio = 1.0
		else:
			next_line()

func next_line():
	if line_index < current_data.lines.size():
		label_text.text = current_data.lines[line_index]
		label_text.visible_ratio = 0
		var t = create_tween()
		t.tween_property(label_text, "visible_ratio", 1.0, 0.4)
		line_index += 1
	else:
		print("UI: Tutorial finished, emitting signal.")
		hide_everything()
		finished.emit() # Ensure this matches what StoryManager expects!

func set_spotlight(target: CanvasItem):
	if target == null:
		return

	var center: Vector2
	var size: Vector2

	if target is Control:
		var rect = target.get_global_rect()
		center = rect.position + rect.size * 0.5
		size = rect.size

	elif target is Node2D:
		center = target.global_position
		size = Vector2(100, 100) # Adjust to match your deck size

	else:
		return

	var mat := dimmer.material as ShaderMaterial
	mat.set_shader_parameter("hole_position", center)
	mat.set_shader_parameter("hole_size", size + Vector2(40, 40))


func position_group_box():
	# We hide it briefly and wait a frame so Godot can calculate 
	# the new box size based on the text length.
	panel.hide()
	await get_tree().process_frame
	
	var screen = get_viewport().get_visible_rect().size
	var margin := 30.0
	var spacing := 50.0 # Space between the highlight and the text box

	# 1. Define the actual boundaries of the highlighted area
	# We use the group_size we calculated + the padding we give the shader
	var padding_v = 80.0 
	var top_boundary = group_center.y - (group_size.y / 2.0) - (padding_v / 2.0)
	var bottom_boundary = group_center.y + (group_size.y / 2.0) + (padding_v / 2.0)

	var pos_x = group_center.x - (panel.size.x / 2.0)
	var pos_y = 0.0

	# 2. Decide: Above or Below?
	# If the center of the group is in the bottom half of the screen, put text ABOVE.
	if group_center.y > (screen.y / 2.0):
		pos_y = top_boundary - panel.size.y - spacing
	else:
		# Otherwise, put it BELOW.
		pos_y = bottom_boundary + spacing

	# 3. Final safety clamps (don't let it go off screen)
	pos_x = clamp(pos_x, margin, screen.x - panel.size.x - margin)
	pos_y = clamp(pos_y, margin, screen.y - panel.size.y - margin)

	panel.global_position = Vector2(pos_x, pos_y)
	panel.show()

func set_group_spotlight():
	var mat := dimmer.material as ShaderMaterial
	
	# Horizontal padding (wider for slots), Vertical padding (smaller so it doesn't hit text)
	var padding = Vector2(100, 80) 
	
	mat.set_shader_parameter("hole_position", group_center)
	mat.set_shader_parameter("hole_size", group_size + padding)
