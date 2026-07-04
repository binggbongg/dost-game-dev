extends Control

@export var lore_data: StoryData

@onready var text_label = $DialogueBox/Panel/TextLabel
@onready var name_label = $DialogueBox/Panel/NameLabel
@onready var display: AnimatedSprite2D = $AnimatedSprite2D
@onready var skip: Button = $Skip
@onready var next: Label = $DialogueBox/Panel/Next
@onready var close_button: TextureButton = $CloseButton

var line_index: int = 0
var is_transitioning := false

func _ready():
	close_button.pressed.connect(_back_pressed)
	next.visible = false

	if lore_data:
		name_label.text = lore_data.character_name

		if lore_data.bgm_to_play:
			AudioManager.play_bgm(lore_data.bgm_to_play)

		display_current_line()
	else:
		print("Error: No Lore Data resource assigned to Intro scene!")

func _input(event):
	if is_transitioning:
		return

	if visible and (
		event.is_action_pressed("ui_accept")
		or (event is InputEventMouseButton and event.pressed)
	):
		if text_label.visible_ratio < 1.0:
			text_label.visible_ratio = 1.0

			# Only show Next if there are more pages
			if line_index < lore_data.lines.size() - 1:
				next.visible = true
		else:
			if line_index < lore_data.lines.size() - 1:
				transition_to_next_page()

func transition_to_next_page():
	is_transitioning = true
	next.visible = false

	var animations = display.sprite_frames.get_animation_names()
	var index = animations.find(display.animation)
	index = (index + 1) % animations.size()

	AudioManager.play_ui_sound("flip")

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Fade out current artwork
	tween.tween_property(display, "modulate:a", 0.0, 0.3)

	# Swap artwork
	tween.tween_callback(func():
		display.animation = animations[index]
		advance_line()
	)

	# Fade in new artwork
	tween.tween_property(display, "modulate:a", 1.0, 0.3)

	tween.tween_callback(func():
		is_transitioning = false
	)

func advance_line():
	line_index += 1

	if line_index < lore_data.lines.size():
		display_current_line()

func display_current_line():
	next.visible = false

	text_label.text = lore_data.lines[line_index]
	text_label.visible_ratio = 0

	var t = create_tween()
	t.tween_property(text_label, "visible_ratio", 1.0, 1.5)

	# Show Next only if this isn't the last dialogue
	if line_index < lore_data.lines.size() - 1:
		t.tween_callback(func():
			next.visible = true
		)

	AudioManager.play_ui_sound("click")
	
func _back_pressed():
	SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
