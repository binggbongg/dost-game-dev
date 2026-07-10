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
	
	button1.disabled = false
	var is_cleared = viewing_chapter < max_unlocked
	
	# If the chapter is already cleared, buttons 2 and 3 stay enabled and visible
	button2.disabled = not (is_cleared or current_lv >= 2)
	button2.modulate = Color(1, 1, 1, 1) if not button2.disabled else Color(0.3, 0.3, 0.3, 0.9)
	
	button3.disabled = not (is_cleared or current_lv >= 3)
	button3.modulate = Color(1, 1, 1, 1) if not button3.disabled else Color(0.3, 0.3, 0.3, 0.9)

	# Reset existing modulations to clear old tweens
	for btn in [button1, button2, button3]:
		if not btn.disabled:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Apply the correct glow based on status
	if is_cleared:
		apply_glow(button3) # Completed chapters always glow on level 3
	elif current_lv == 1:
		apply_glow(button1)
	elif current_lv == 2:
		apply_glow(button2)
	elif current_lv >= 3:
		apply_glow(button3)


func _on_start_button_pressed():
	AudioManager.play_ui_sound("click")
	
	# Clicking start on a cleared chapter signifies redoing it: force level 1 setup
	if PlayerProfile.selected_chapter < PlayerProfile.max_unlocked_chapters:
		PlayerProfile.current_level = 1
		var path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
		if ResourceLoader.exists(path):
			PlayerProfile.set_next_level(load(path))
			
	if not PlayerProfile.tutorial_steps_completed.get("battle_tutorial", false) and PlayerProfile.current_phase == 1:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1_Tutorial.tscn"
	else:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"
	
	get_tree().change_scene_to_file("res://scenes/ui/DeckBuilder.tscn")

func back_button_pressed():
	print("back button clicked!")
	# If leaving an active unfinished chapter run, force reset progress to level 1
	if PlayerProfile.selected_chapter == PlayerProfile.max_unlocked_chapters:
		PlayerProfile.current_level = 1
		var path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
		if ResourceLoader.exists(path):
			PlayerProfile.set_next_level(load(path))
	SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
	print("backed")
	
func apply_glow(node: CanvasItem):
	var tween = create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.8) # Brighten
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8) # Return to normal
