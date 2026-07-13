extends CanvasLayer

@export var lore_data: StoryData
@export var next_scene: PackedScene

@onready var text_label = $DialogueBox/Panel/TextLabel
@onready var name_label = $DialogueBox/Panel/NameLabel
@onready var display: AnimatedSprite2D = $AnimatedSprite2D
@onready var skip: Button = $Skip
@onready var next: Label = $DialogueBox/Panel/Next
@onready var close_button: TextureButton = $CloseButton
@onready var dialogue_panel = $DialogueBox/Panel
var current_blocks: PackedStringArray
var block_index: int = 0
var line_index: int = 0
var is_transitioning := false

func _ready():
	close_button.pressed.connect(_back_pressed)
	skip.pressed.connect(skip_pressed)
	
	# Connect the dialogue box panel directly to handle text advancement clicks safely
	if dialogue_panel:
		dialogue_panel.gui_input.connect(_on_dialogue_panel_gui_input)

	next.visible = false

	if lore_data:
		name_label.text = lore_data.character_name
		if lore_data.bgm_to_play:
			AudioManager.play_bgm(lore_data.bgm_to_play)
		display_current_line()
	else:
		push_error("No Lore Data resource assigned!")

func skip_pressed():
	AudioManager.play_ui_sound("click")
	if is_transitioning:
		return
	finish_intro()

## Keyboards/Controllers still use this safely without breaking mouse interactions
func _input(event):

	if is_transitioning or not visible:
		return

	# ONLY process keyboard space/enter actions here
	if event.is_action_pressed("ui_accept"):
		advance_dialogue_logic()

## New Dedicated Click Zone Handler for the Dialogue Box Panel
func _on_dialogue_panel_gui_input(event: InputEvent):
	if is_transitioning:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_dialogue_logic()

func advance_dialogue_logic():
	# Finish typing first
	if text_label.visible_ratio < 1.0:
		text_label.visible_ratio = 1.0
		return

	# Still more dialogue blocks in this slide?
	if block_index < current_blocks.size() - 1:
		block_index += 1
		show_current_block()
		return

	# Otherwise move to the next slide
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

	tween.tween_property(display, "modulate:a", 0.0, 0.3)

	tween.tween_callback(func():
		display.animation = animations[index]
		advance_line()
	)

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

	# Split one slide into dialogue blocks using blank lines
	current_blocks = lore_data.lines[line_index].split("\n\n")
	block_index = 0

	show_current_block()
	
func _back_pressed():
	AudioManager.play_ui_sound("click")
	SceneTransition.change_scene_path("res://scenes/menus/play.tscn")

func finish_intro():
	if next_scene:
		SceneTransition.change_scene(next_scene)

func show_current_block():
	text_label.text = current_blocks[block_index]
	text_label.visible_ratio = 0.0

	var tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, 1.5)

	tween.tween_callback(func():
		next.visible = true
	)
