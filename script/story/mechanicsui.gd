# MechanicsUI.gd
extends CanvasLayer

signal finished

@onready var panel = $MechanicsBox/MechanicsPanel
@onready var label_text = $MechanicsBox/MechanicsPanel/TextLabel
@onready var label_name = $MechanicsBox/MechanicsPanel/NameLabel
@onready var dimmer = $Dimmer # The ColorRect
@onready var highlight_layer = $HighlightLayer
var is_active = false
var current_data: StoryData
var line_index = 0

func _ready():
	# Ensure the Dimmer ColorRect is set to "Full Rect" in the Layout menu!
	hide_everything()

func hide_everything():
	visible = false
	dimmer.hide()
	panel.hide()
	is_active = false

func start_tutorial(data: StoryData, target_node: Control = null):
	current_data = data
	line_index = 0
	label_name.text = data.character_name
	
	if target_node:
		if target_node.name == "ChapterOne":
			# Custom position for the last tutorial
			panel.global_position = Vector2(700, 650) # Adjust these values
		else:
			await position_box(target_node)
	
	visible = true
	dimmer.show() # <--- THIS IS THE FIX FOR THE DIMMER
	panel.show()
	is_active = true
	next_line()
func position_box(target: Control):
	await get_tree().process_frame

	var t_rect = target.get_global_rect()
	var screen = get_viewport().get_visible_rect().size
	var margin := 20.0
	var spacing := 30.0

	# Center horizontally on the target
	var pos = Vector2(
		t_rect.position.x + (t_rect.size.x / 2.0) - (panel.size.x / 2.0),
		0
	)

	# Try placing below first
	var below_y = t_rect.end.y + spacing

	# Try placing above if below won't fit
	var above_y = t_rect.position.y - panel.size.y - spacing

	if below_y + panel.size.y <= screen.y - margin:
		pos.y = below_y
	elif above_y >= margin:
		pos.y = above_y
	else:
		# The target is too large (like CharacterSpotlight),
		# so pin the tutorial panel to the top of the screen.
		pos.y = margin

	# Keep the panel inside the screen horizontally
	pos.x = clamp(
		pos.x,
		margin,
		screen.x - panel.size.x - margin
	)
	print("Target:", target.name)
	print("Target rect:", t_rect)
	print("Screen:", screen)
	print("Final panel pos:", pos)
	panel.global_position = pos

func next_line():
	if line_index < current_data.lines.size():
		label_text.text = current_data.lines[line_index]
		label_text.visible_ratio = 0
		var t = create_tween()
		t.tween_property(label_text, "visible_ratio", 1.0, 0.4)
		line_index += 1
	else:
		hide_everything()
		finished.emit()

func _input(event):
	if not is_active: return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		if label_text.visible_ratio < 1.0:
			label_text.visible_ratio = 1.0
		else:
			next_line()
