extends CanvasLayer

@export var lore_data: StoryData
@export var next_scene: PackedScene

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
	skip.pressed.connect(skip_pressed)

	next.visible = false

	if lore_data:
		name_label.text = lore_data.character_name

		if lore_data.bgm_to_play:
			AudioManager.play_bgm(lore_data.bgm_to_play)

		display_current_line()
	else:
		push_error("No Lore Data resource assigned!")

func skip_pressed():
	if is_transitioning:
		return

	finish_intro()

func _input(event):
	if is_transitioning:
		return

	if visible and (
		event.is_action_pressed("ui_accept")
		or (event is InputEventMouseButton and event.pressed)
	):
		# Finish typing first
		if text_label.visible_ratio < 1.0:
			text_label.visible_ratio = 1.0

			# Only show Next if another page exists
			if line_index < lore_data.lines.size() - 1:
				next.visible = true
		else:
			if line_index < lore_data.lines.size() - 1:
				transition_to_next_page()
			else:
				finish_intro()

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
	else:
		finish_intro()

func display_current_line():
	next.visible = false

	text_label.text = lore_data.lines[line_index]
	text_label.visible_ratio = 0.0

	var tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, 1.5)

	# Only show Next if there is another page
	if line_index < lore_data.lines.size() - 1:
		tween.tween_callback(func():
			next.visible = true
		)

	AudioManager.play_ui_sound("click")

func _back_pressed():
	SceneTransition.change_scene_path("res://scenes/menus/play.tscn")

func finish_intro():
	if next_scene:
		SceneTransition.change_scene(next_scene)
