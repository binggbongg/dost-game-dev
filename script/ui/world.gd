extends Control

@export var lounge_scene: PackedScene = load("res://scenes/menus/lounge.tscn")

func _ready() -> void:
	load_current_chapter_cutscene()

func load_current_chapter_cutscene() -> void:
	var chapter_num = PlayerProfile.selected_chapter
	var cutscene_path = "res://scenes/pre_post_battles/cutscenes/chapter_%d.tscn" % chapter_num
	
	print("[CutscenePlayer] Loading cutscene for Chapter: ", chapter_num)
	
	if not ResourceLoader.exists(cutscene_path):
		print("[Error] Cutscene file does not exist: ", cutscene_path)
		SceneTransition.change_scene_path("res://scenes/menus/Lounge.tscn")
		return
		
	var cutscene_resource = load(cutscene_path)
	if cutscene_resource:
		var cutscene_instance = cutscene_resource.instantiate()
		add_child(cutscene_instance)
		
		cutscene_instance.cutscene_finished.connect(_on_cutscene_player_finished)
		
		var story_data_path = "res://data/StoryData/Post Boss/chapter_%d.tres" % chapter_num
		
		var story_data: StoryData = null
		if ResourceLoader.exists(story_data_path):
			story_data = load(story_data_path) as StoryData
		
		if cutscene_instance.has_method("start_world_cutscene"):
			cutscene_instance.start_world_cutscene(story_data)
		else:
			print("[Error] Loaded cutscene is missing start_world_cutscene() method!")

func _on_cutscene_player_finished() -> void:
	print("[World] Cutscene completed. Awarding progression rewards...")
	
	PlayerProfile.tutorial_steps_completed["cut_scene"] = true
	var current_chap = PlayerProfile.selected_chapter
	var fragment_id = "chapter_%d_fragment" % current_chap
	PlayerProfile.add_fragment_to_inventory(fragment_id)
	
	SceneTransition.change_scene(lounge_scene)
