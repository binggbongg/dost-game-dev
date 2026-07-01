extends CanvasLayer

@export var lore_data: StoryData 
@export var next_scene: PackedScene

@onready var text_label = $DialogueBox/Panel/TextLabel
@onready var name_label = $DialogueBox/Panel/NameLabel
@onready var illustration_rect = $TextureRect # The small image inside the scroll
@onready var display: AnimatedSprite2D = $AnimatedSprite2D
@onready var skip: Button = $Skip

var line_index: int = 0

func _ready():
	skip.pressed.connect(skip_pressed)
	if lore_data:
		name_label.text = lore_data.character_name
		
		if lore_data.portrait:
			illustration_rect.texture = lore_data.portrait
			
		if lore_data.bgm_to_play:
			AudioManager.play_bgm(lore_data.bgm_to_play)
			
		display_current_line()
	else:
		print("Error: No Lore Data resource assigned to Intro scene!")

func skip_pressed():
	finish_intro()
func _input(event):
	var animations = display.sprite_frames.get_animation_names()
	var index = animations.find(display.animation)
	index = (index + 1) % animations.size()
	
	if visible and (event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed):
		if text_label.visible_ratio < 1.0:
			text_label.visible_ratio = 1.0 # Skip typing
		else:
			var tween = create_tween()
			tween.tween_property(display, "modulate:a", 0.0, 0.2)
			tween.tween_callback(func():
				display.animation = animations[index]
			)
			tween.tween_property(display, "modulate:a", 1.0, 0.2)
			advance_line()

func advance_line():
	line_index += 1
	if line_index < lore_data.lines.size():
		display_current_line()
	else:
		finish_intro()

func display_current_line():
	text_label.text = lore_data.lines[line_index]
	
	text_label.visible_ratio = 0
	var t = create_tween()
	t.tween_property(text_label, "visible_ratio", 1.0, 1.5)
	
	AudioManager.play_ui_sound("click")

func finish_intro():
	if next_scene:
		SceneTransition.change_scene(next_scene)
