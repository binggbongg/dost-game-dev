# storyui.gd
extends CanvasLayer

signal sequence_finished

@onready var portrait = $Portrait
@onready var dialogue_box = $DialogueBox
@onready var mechanics_box = $MechanicsBox
@onready var dimmer = $Dimmer

var current_data: StoryData
var line_index: int = 0
var active_label: Label = null

func _ready():
	# Start completely invisible
	hide_everything()

func hide_everything():
	visible = false
	dimmer.hide()
	portrait.hide()
	dialogue_box.hide()
	mechanics_box.hide()
	$Background.hide()

func start_sequence(data: StoryData, target_node: Control = null):
	if data == null:
		push_error("StoryManager: No data provided!")
		return
		
	# 1. Clean slate
	hide_everything()
	current_data = data
	line_index = 0
	visible = true # Show the layer
	
	print("Starting Story Mode: ", StoryData.Type.keys()[data.type])

	# 2. Logic for Tutorial vs Dialogue
	if data.type == StoryData.Type.TUTORIAL:
		# --- TUTORIAL MODE (Small Box) ---
		mechanics_box.show()
		active_label = $MechanicsBox/MechanicsPanel/TextLabel
		$MechanicsBox/MechanicsPanel/NameLabel.text = data.character_name
		
		# Dimmer helps focus on the button
		dimmer.show()
		
		if target_node:
			position_mechanic_box(target_node)
	else:
		# --- DIALOGUE/LORE MODE (Big Box) ---
		dialogue_box.show()
		active_label = $DialogueBox/Panel/TextLabel
		$DialogueBox/Panel/NameLabel.text = data.character_name
		
		# Show portrait ONLY if it's not a tutorial and we have a texture
		if data.portrait:
			portrait.texture = data.portrait
			portrait.show()
			
		if data.type == StoryData.Type.LORE:
			$Background.show()
	
	next_line()

func position_mechanic_box(target: Control):
	await get_tree().process_frame
	var m_panel = $MechanicsBox/MechanicsPanel
	var target_rect = target.get_global_rect()
	var screen = get_viewport().get_visible_rect().size
	
	# Try placing it directly below the button
	var pos = Vector2(
		target_rect.position.x + (target_rect.size.x / 2) - (m_panel.size.x / 2),
		target_rect.end.y + 40 # 40 pixels gap
	)
	
	# If it's too low, put it above
	if pos.y + m_panel.size.y > screen.y:
		pos.y = target_rect.position.y - m_panel.size.y - 40
		
	pos.x = clamp(pos.x, 50, screen.x - m_panel.size.x - 50)
	m_panel.global_position = pos

func next_line():
	if line_index < current_data.lines.size():
		display_text(current_data.lines[line_index])
		line_index += 1
	else:
		hide_everything()
		sequence_finished.emit()

func display_text(content: String):
	if active_label:
		active_label.text = content
		active_label.visible_ratio = 0
		create_tween().tween_property(active_label, "visible_ratio", 1.0, 0.5)

func _input(event):
	if not visible: return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if active_label and active_label.visible_ratio < 1.0:
			active_label.visible_ratio = 1.0
		else:
			next_line()
