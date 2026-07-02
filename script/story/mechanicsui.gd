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

func start_group_tutorial(data: StoryData, targets: Array):
	current_data = data
	line_index = 0
	label_name.text = data.character_name

	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)

	for target in targets:

		if !is_instance_valid(target):
			continue

		if target is Control:
			var rect = target.get_global_rect()
			min_pos.x = min(min_pos.x, rect.position.x)
			min_pos.y = min(min_pos.y, rect.position.y)

			max_pos.x = max(max_pos.x, rect.end.x)
			max_pos.y = max(max_pos.y, rect.end.y)

		elif target is Node2D:
			var art: TextureRect = target.get_node_or_null("Sprite2D") as TextureRect
			if art != null:
				var rect := art.get_global_rect()
				min_pos.x = min(min_pos.x, rect.position.x)
				min_pos.y = min(min_pos.y, rect.position.y)
				max_pos.x = max(max_pos.x, rect.end.x)
				max_pos.y = max(max_pos.y, rect.end.y)
			else:
				var pos = target.global_position
				min_pos.x = min(min_pos.x, pos.x)
				min_pos.y = min(min_pos.y, pos.y)
				max_pos.x = max(max_pos.x, pos.x + 100)
				max_pos.y = max(max_pos.y, pos.y + 100)

	if min_pos == Vector2(INF, INF):
		min_pos = Vector2.ZERO
		max_pos = Vector2(100,100)
	group_center = (min_pos + max_pos) / 2.0
	group_size = max_pos - min_pos
	position_group_box()
	set_group_spotlight()
	visible = true
	dimmer.show()
	panel.show()
	is_active = true
	next_line()

func position_group_box():

	var screen = get_viewport().get_visible_rect().size

	var spacing := 40.0
	var margin := 20.0

	var pos = Vector2(
		group_center.x - panel.size.x/2,
		group_center.y - panel.size.y - spacing
	)

	pos.x = clamp(
		pos.x,
		margin,
		screen.x-panel.size.x-margin
	)

	pos.y = clamp(
		pos.y,
		margin,
		screen.y-panel.size.y-margin
	)

	panel.global_position = pos
	
	
func set_group_spotlight():

	var mat := dimmer.material as ShaderMaterial

	mat.set_shader_parameter(
		"hole_position",
		group_center
	)

	mat.set_shader_parameter(
		"hole_size",
		group_size + Vector2(120,120)
	)
