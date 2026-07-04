extends Control

@export var phase1: PackedScene
@export var phase2: PackedScene
@export var phase3: PackedScene

@onready var button1 = $Buttons/Phase1
@onready var button2 = $Buttons/Phase2
@onready var button3 = $Buttons/Phase3

@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer

var tutorial_active = false
 
func _ready() -> void:
	update_button_locks()
	
	button1.pressed.connect(func(): phase_button_pressed(phase1))
	button2.pressed.connect(func(): phase_button_pressed(phase2))
	button3.pressed.connect(func(): phase_button_pressed(phase3))
	dimmer.hide()

	if not PlayerProfile.tutorial_steps_completed.get("chapter_intro", false):
		start_chapter_intro()

func start_chapter_intro():
	tutorial_active = true
	var base_path = "res://data/StoryData/Tutorial/ChapterScreen/"
	
	var tour_steps = [
	[$Buttons/Phase1, "Chapter1Intro.tres"]
	]
	for step in tour_steps:
		await highlight_and_talk(step[0], base_path + step[1])
		tutorial_active = false
		PlayerProfile.tutorial_steps_completed["chapter_intro"] = true
		SaveManager.save_game()

func highlight_and_talk(node: Control, data_path: String):
	var copy := node.duplicate()
	highlight_layer.add_child(copy)
	
	var visual_transform = node.get_global_transform_with_canvas()
	copy.global_position = visual_transform.get_origin()
	copy.scale = visual_transform.get_scale()
	
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await StoryManager.play_tutorial(data_path, node)

	copy.queue_free()
	node.mouse_filter = Control.MOUSE_FILTER_STOP
func phase_button_pressed(current_phase):
	AudioManager.play_ui_sound("click")

	if current_phase:
		if not PlayerProfile.tutorial_steps_completed.get("battle_tutorial", false):
			PlayerProfile.pending_scene = "res://scenes/levels/Level1_Tutorial.tscn"
		else:
			PlayerProfile.pending_scene = current_phase
		print("DEBUGGING NOW IN MAP" + PlayerProfile.pending_scene)
		get_tree().change_scene_to_file("res://scenes/ui/DeckBuilder.tscn")

func update_button_locks():
	var max_unlocked = PlayerProfile.max_unlocked_chapters
	
	button1.disabled = false
	
	if max_unlocked >= 2:
		button2.disabled = false
		button2.modulate = Color(1, 1, 1, 1)
	else:
		button2.disabled = true
		button2.modulate = Color(0.3, 0.3, 0.3, 0.9)
	
	if max_unlocked == 3:
		button3.disabled = false
		button3.modulate = Color(1, 1, 1, 1)
	else:
		button3.disabled = true
		button3.modulate = Color(0.3, 0.3, 0.3, 0.9)
