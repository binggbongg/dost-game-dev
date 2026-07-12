extends Control

@export var leaderboard_name: String = "chapter_1"

@onready var rank_label = $ScrollContainer/HBoxContainer/RankColumn/RankLabel
@onready var name_label = $ScrollContainer/HBoxContainer/NameColumn/NameLabel
@onready var score_label = $ScrollContainer/HBoxContainer/ScoreColumn/ScoreLabel
@onready var left_button = $LeftButton
@onready var right_button = $RightButton
@onready var chapter_title_label = $ChapterLabel

var chapter_name = "chapter_"
var chapter_key = 1

func _ready() -> void:
	# Clear out any editor placeholder texts before building live listings
	rank_label.text = ""
	name_label.text = ""
	score_label.text = ""
	
	if left_button:
		left_button.pressed.connect(_on_left_button_pressed)
	
	if right_button:
		right_button.pressed.connect(_on_right_button_pressed)
	
	_load_talo_leaderboard()

func _load_talo_leaderboard() -> void:
	print("[LEADERBOARD] Contacting Talo backend services for: ", leaderboard_name)
	rank_label.text = "..."
	name_label.text = "Loading entries..."
	score_label.text = "..."
	
	if is_instance_valid(chapter_title_label):
		chapter_title_label.text = "Chapter " + str(chapter_key)
	
	# Dynamically clamp and lock navigation button actions at boundaries (Chapters 1 and 3)
	if left_button:
		left_button.disabled = (chapter_key <= 1)
	if right_button:
		right_button.disabled = (chapter_key >= 3)
	
	var options := Talo.leaderboards.GetEntriesOptions.new()
	options.page = 0
	
	var res = await Talo.leaderboards.get_entries(leaderboard_name, options)
	
	if not res or res.entries.is_empty():
		name_label.text = "No high scores recorded yet!"
		return
	
	var ranks_text := ""
	var names_text := ""
	var scores_text := ""
	
	for i in range(res.entries.size()):
		var entry = res.entries[i]
		#print("--- INSPECTING ENTRY VARIABLES ---")
		#print(inst_to_dict(entry))
		
		var player_display_name = "Guest"
		if entry.player_alias:
			if entry.player_alias.get("display_name"):
				print("got the display name --leaderboard")
				player_display_name = str(entry.player_alias.get("display_name"))
			elif entry.player_alias.get("identifier"):
				print("got the identifer --leaderboard")
				player_display_name = str(entry.player_alias.get("identifier"))
		
		var assigned_rank = "—"
		if entry.props and typeof(entry.props) == TYPE_ARRAY:
			for prop_object in entry.props:
				if prop_object.get("key") == "rank":
					assigned_rank = str(prop_object.get("value"))
					break
		
		ranks_text += "%s\n" % assigned_rank
		names_text += "%s\n" % player_display_name
		scores_text += "%s\n" % str(entry.score)
	
	rank_label.text = ranks_text
	name_label.text = names_text
	score_label.text = scores_text
	
	print("[LEADERBOARD] Board population completed successfully.")

func _on_left_button_pressed() -> void:
	if chapter_key > 1:
		if has_node("/root/AudioManager") and AudioManager.has_method("play_ui_sound"):
			AudioManager.play_ui_sound("click")
			
		chapter_key -= 1
		leaderboard_name = chapter_name + str(chapter_key)
		chapter_title_label.text = "Chapter " + str(chapter_key)
		_load_talo_leaderboard()

func _on_right_button_pressed() -> void:
	if chapter_key < 3:
		if has_node("/root/AudioManager") and AudioManager.has_method("play_ui_sound"):
			AudioManager.play_ui_sound("click")
			
		chapter_key += 1
		leaderboard_name = chapter_name + str(chapter_key)
		chapter_title_label.text = "Chapter " + str(chapter_key)
		_load_talo_leaderboard()
