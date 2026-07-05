extends Control

@export var leaderboard_name: String = "chapter_1"

@onready var rank_label = $ScrollContainer/HBoxContainer/RankColumn/RankLabel
@onready var name_label = $ScrollContainer/HBoxContainer/NameColumn/NameLabel
@onready var score_label = $ScrollContainer/HBoxContainer/ScoreColumn/ScoreLabel

func _ready() -> void:
	# Clear out any editor placeholder texts before building live listings
	rank_label.text = ""
	name_label.text = ""
	score_label.text = ""
	
	_load_talo_leaderboard()

func _load_talo_leaderboard() -> void:
	print("[LEADERBOARD] Contacting Talo backend services for: ", leaderboard_name)
	
	# 1. Configure the pagination options matching Talo's API layout structures
	var options := Talo.leaderboards.GetEntriesOptions.new()
	options.page = 0
	
	# 2. Pull down the asynchronous paginated result matrix tracking package
	var res = await Talo.leaderboards.get_entries(leaderboard_name, options)
	
	if not res or res.entries.is_empty():
		name_label.text = "No high scores recorded yet!"
		return

	# Temporary tracking caches to build cleanly formatted columns
	var ranks_text := ""
	var names_text := ""
	var scores_text := ""

	# 3. Iterate over the returned data pool sequentially
	for i in range(res.entries.size()):
		var entry = res.entries[i] # This is a TaloLeaderboardEntry object
		
		# Pull player identifier name securely from the alias package mappings
		var player_display_name = "Anonymous Player"
		if entry.alias and not entry.alias.name.is_empty():
			player_display_name = entry.alias.name
		
		# 🌟 HANDLE THE CHAPTER RANK REQUIREMENT GATING
		# Look for custom ranking metadata passed inside your entry props dictionary
		var assigned_rank = "—"
		if entry.props and entry.props.has("rank"):
			assigned_rank = str(entry.props.get("rank"))
		elif entry.props and entry.props.has("chapter_cleared") and entry.props.get("chapter_cleared") == true:
			assigned_rank = "Cleared"

		# Append strings to our column data buffers separated by newlines
		ranks_text += "%s\n" % assigned_rank
		names_text += "%d. %s\n" % [(i + 1), player_display_name]
		scores_text += "%s\n" % str(entry.score)

	# 4. Paint the text blocks directly into the User Interface nodes
	rank_label.text = ranks_text
	name_label.text = names_text
	score_label.text = scores_text
	
	print("[LEADERBOARD] Board population completed successfully.")
