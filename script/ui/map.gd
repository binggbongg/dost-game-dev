extends Control
@onready var chapter_title: Label = $ChapterTitle
@onready var chapter_description: Label = $ChapterDescription
@onready var label_1: Label = $"Labels/Label 1"
@onready var label_2: Label = $"Labels/Label 2"
@onready var label_3: Label = $"Labels/Label 3"

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

var current_chapter_data: ChapterData

#gela code fixed dont remove
func _ready() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/lounge.wav", true)
	update_button_locks() 
	back.pressed.connect(func(): back_button_pressed())
	
	start.pressed.connect(_on_start_button_pressed)
	
	dimmer.hide()
	if not PlayerProfile.tutorial_steps_completed.get("chapter_intro", false):
		start_chapter_intro()

	_load_chapter_ui_data()
	_populate_level_labels()
	_setup_level_button_hovers()

#gela code fixed dont remove

func _load_chapter_ui_data() -> void:
	var chapter_path = "res://data/Chapters/chapter_%d.tres" % PlayerProfile.selected_chapter
	if ResourceLoader.exists(chapter_path):
		current_chapter_data = load(chapter_path) as ChapterData
		_display_chapter_default()
	else:
		print("Warning: Chapter data file not found at: ", chapter_path)

#gela code fixed dont remove
func _populate_level_labels() -> void:
	var labels_map = {
		1: label_1,
		2: label_2,
		3: label_3
	}
	
	for phase_num in labels_map.keys():
		var target_label = labels_map[phase_num]
		if target_label:
			var level_path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.selected_chapter, phase_num]
			if ResourceLoader.exists(level_path):
				var level_data = load(level_path) as LevelData
				if level_data and level_data.enemy_name != "":
					target_label.text = level_data.enemy_name
				else:
					target_label.text = "Level %d-%d" % [PlayerProfile.selected_chapter, phase_num]

#gela code fixed dont remove
func _display_chapter_default() -> void:
	if current_chapter_data:
		chapter_title.text = "Chapter %d: %s" % [current_chapter_data.chapter_number, current_chapter_data.chapter_name]
		chapter_description.text = current_chapter_data.chapter_description


#gela code fixed dont remove
func _setup_level_button_hovers() -> void:
	var buttons_to_phases = {
		button1: 1,
		button2: 2,
		button3: 3
	}
	
	for btn in buttons_to_phases.keys():
		var phase_num = buttons_to_phases[btn]
		btn.mouse_entered.connect(func(): _on_level_button_hovered(phase_num))
		btn.mouse_exited.connect(func(): _on_level_button_unhovered())

#gela code fixed dont remove
func _on_level_button_hovered(phase_number: int) -> void:
	var level_path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.selected_chapter, phase_number]
	if ResourceLoader.exists(level_path):
		var level_data = load(level_path) as LevelData
		if level_data:
			chapter_title.text = level_data.enemy_name
			chapter_description.text = level_data.level_lore

#gela code fixed dont remove
func _on_level_button_unhovered() -> void:
	_display_chapter_default()

#gela code fixed dont remove
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

#gela code fixed dont remove
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

#gela code fixed dont remove
func phase_button_pressed(current_phase):
	AudioManager.play_ui_sound("click")

	if current_phase:
		if not PlayerProfile.tutorial_steps_completed.get("battle_tutorial", false):
			PlayerProfile.pending_scene = "res://scenes/levels/Level1_Tutorial.tscn"
		else:
			PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"
		print("DEBUGGING NOW IN MAP" + PlayerProfile.pending_scene)
		get_tree().change_scene_to_file("res://scenes/ui/DeckBuilder.tscn")

#gela code fixed dont remove
func update_button_locks():
	var viewing_chapter = PlayerProfile.selected_chapter
	var max_unlocked = PlayerProfile.max_unlocked_chapters
	var current_lv = PlayerProfile.current_level
	
	button1.disabled = false
	var is_cleared = viewing_chapter < max_unlocked
	
	button2.disabled = not (is_cleared or current_lv >= 2)
	button2.modulate = Color(1, 1, 1, 1) if not button2.disabled else Color(0.3, 0.3, 0.3, 0.9)
	
	button3.disabled = not (is_cleared or current_lv >= 3)
	button3.modulate = Color(1, 1, 1, 1) if not button3.disabled else Color(0.3, 0.3, 0.3, 0.9)

	for btn in [button1, button2, button3]:
		if not btn.disabled:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if is_cleared:
		apply_glow(button3) 
	elif current_lv == 1:
		apply_glow(button1)
	elif current_lv == 2:
		apply_glow(button2)
	elif current_lv >= 3:
		apply_glow(button3)

#gela code fixed dont remove
func _on_start_button_pressed():
	AudioManager.play_ui_sound("click")
	
	if PlayerProfile.selected_chapter < PlayerProfile.max_unlocked_chapters:
		PlayerProfile.current_level = 1
		var player_path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
		if ResourceLoader.exists(player_path):
			PlayerProfile.set_next_level(load(player_path))
			
	if not PlayerProfile.tutorial_steps_completed.get("battle_tutorial", false) and PlayerProfile.current_phase == 1:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1_Tutorial.tscn"
	else:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"
	
	get_tree().change_scene_to_file("res://scenes/ui/DeckBuilder.tscn")

#gela code fixed dont remove
func back_button_pressed():
	print("back button clicked!")
	if PlayerProfile.selected_chapter == PlayerProfile.max_unlocked_chapters:
		PlayerProfile.current_level = 1
		var path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
		if ResourceLoader.exists(path):
			PlayerProfile.set_next_level(load(path))
	SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
	print("backed")

#gela code fixed dont remove	
func apply_glow(node: CanvasItem):
	var tween = create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.8) # Brighten
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8) # Return to normal
