extends Control

@export var phase1: PackedScene
@export var phase2: PackedScene
@export var phase3: PackedScene
@onready var start: TextureButton = $Start

@onready var button1 = $Buttons/Phase1
@onready var button2 = $Buttons/Phase2
@onready var button3 = $Buttons/Phase3
@onready var back: TextureButton = $Back

@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer

var tutorial_active = false
 
func _ready() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/lounge.wav", true)
	update_button_locks() # We update this below
	back.pressed.connect(func(): back_button_pressed())
	
	# UPDATE: Start button now launches current progress
	start.pressed.connect(_on_start_button_pressed)
	
	dimmer.hide()
	if not PlayerProfile.tutorial_steps_completed.get("chapter_intro", false):
		start_chapter_intro()


func start_chapter_intro():
	tutorial_active = true
	var base_path = "res://data/StoryData/Tutorial/ChapterScreen/"
	
	var tour_steps = [
	[start, "Chapter1Intro.tres"]
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
			PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"
		print("DEBUGGING NOW IN MAP" + PlayerProfile.pending_scene)
		get_tree().change_scene_to_file("res://scenes/ui/DeckBuilder.tscn")

func update_button_locks():
	var viewing_chapter = PlayerProfile.selected_chapter
	var max_unlocked = PlayerProfile.max_unlocked_chapters
	var current_lv = PlayerProfile.current_level
	
	# Level 1 is always valid
	button1.disabled = false
	
	# If we are looking at an old chapter, everything is valid.
	# If looking at current chapter, unlock based on current_level progress.
	var is_cleared = viewing_chapter < max_unlocked
	
	button2.disabled = not (is_cleared or current_lv >= 2)
	button2.modulate = Color(1, 1, 1, 1) if not button2.disabled else Color(0.3, 0.3, 0.3, 0.9)
	
	button3.disabled = not (is_cleared or current_lv >= 3)
	button3.modulate = Color(1, 1, 1, 1) if not button3.disabled else Color(0.3, 0.3, 0.3, 0.9)

func _on_start_button_pressed():
	AudioManager.play_ui_sound("click")
	# Logic for tutorial vs normal level
	if not PlayerProfile.tutorial_steps_completed.get("battle_tutorial", false) and PlayerProfile.current_phase == 1:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1_Tutorial.tscn"
	else:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"
	
	get_tree().change_scene_to_file("res://scenes/ui/DeckBuilder.tscn")


func back_button_pressed():
	print("back button clicked!")
	SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
	print("backed")
