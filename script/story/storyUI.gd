extends CanvasLayer

signal sequence_finished

@onready var background = $Background
@onready var dimmer = $Dimmer
@onready var text_label = $DialogueBox/Panel/TextLabel
@onready var name_label = $DialogueBox/Panel/NameLabel
@onready var portrait = $Portrait
@onready var display: AnimatedSprite2D = $AnimatedSprite2D

var current_data: StoryData
var line_index: int = 0

func _ready():
	hide()

func start_sequence(data: StoryData):
	current_data = data
	line_index = 0
	show()
	
	# Logic for Lore vs Tutorial
	background.visible = (data.type == StoryData.Type.LORE)
	dimmer.visible = (data.type == StoryData.Type.TUTORIAL)
	
	if data.background: background.texture = data.background
	if data.portrait: portrait.texture = data.portrait
	name_label.text = data.character_name
	
	next_line()

func next_line():
	if line_index < current_data.lines.size():
		display_text(current_data.lines[line_index])
		line_index += 1
	else:
		end_sequence()

func display_text(content: String):
	# Using typewriter effect
	text_label.text = content
	text_label.visible_ratio = 0
	var t = create_tween()
	t.tween_property(text_label, "visible_ratio", 1.0, 1.0)
	AudioManager.play_ui_sound("click") # Play blip sound

func _input(event):
	if visible and (event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed):
		if text_label.visible_ratio < 1.0:
			text_label.visible_ratio = 1.0 # Skip typing
		else:
			next_line()

func end_sequence():
	hide()
	sequence_finished.emit()
