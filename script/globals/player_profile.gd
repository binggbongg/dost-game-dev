extends Node
signal profile_updated # Emitted when name, character, or rank changes
signal coins_changed(new_amount: int)

var is_profile_initialized: bool = false

var current_phase: int = 1
var current_level: int = 1
var next_level_resource: LevelData = load("res://data/Levels/level_1-1.tres")

#setters
var player_name: String = "Default Player":
	set(value):
		player_name = value
		profile_updated.emit()

var selected_character: String = "None":
	set(value):
		selected_character = value
		profile_updated.emit()

var player_rank: String = "Starter":
	set(value):
		player_rank = value
		profile_updated.emit()
var tutorial_steps_completed: Dictionary = {
	"lounge_tour": false,
	"chapter_intro": false,
	"battle_tutorial": false,
	"deck_builder": false
}
var owned_cards: Array[String] = []
var current_deck: Array[String] = []
var pending_scene: String = ""
func add_card_to_inventory(card_path: String):
	if not owned_cards.has(card_path):
		owned_cards.append(card_path)
		print("Added to inventory: ", card_path)
	SaveManager.save_game()

var is_tutorial_fight: bool = false
var level: int = 1
var experience: int = 0
var coins: int = 100:
	set(value):
		coins = value
		coins_changed.emit(coins) 

# -- progression systems --
var max_unlocked_chapters = 1
var high_scores: Dictionary = {}

var run_turns: int = 0
var run_damage_taken: int = 0
var run_combos_played: int = 0
var run_items_used: int = 0

func reset_run_counter():
	run_turns = 0
	run_damage_taken = 0
	run_combos_played = 0
	run_items_used = 0

# -- initialization logic --
func initialize_profile(new_name: String, character_id: String):
	self.player_name = new_name
	self.selected_character = character_id
	self.player_rank = "Starter"
	self.coins = 100
	
	level = 1
	experience = 0
	is_tutorial_fight = false
	
	tutorial_steps_completed = {
		"lounge_tour": false,
		"chapter_intro": false,
		"battle_tutorial": false,
		"deck_builder": false
	}
	is_tutorial_fight = false
	
	max_unlocked_chapters = 1
	high_scores.clear()
	reset_run_counter()
	
	is_profile_initialized = true
	print("Profile Initialized for: ", player_name)

func set_rank(new_rank: String):
	player_rank = new_rank

#Money logic
func add_coins(amount: int) -> void:
	if amount <= 0: return
	self.coins += amount 

func spend_coins(amount: int) -> bool:
	if can_afford(amount):
		self.coins -= amount
		return true
	return false

func can_afford(amount: int) -> bool:
	return coins >= amount

func get_current_level_data() -> LevelData:
	return next_level_resource
	
	
func update_high_score(level_id: String, score: int) -> bool:
	if not high_scores.has(level_id):
		high_scores[level_id] = 0
	
	if score > high_scores[level_id]:
		high_scores[level_id] = score
		SaveManager.save_game()
		return true
	return false
func advance_to_next_level() -> void:
	var next_l := current_level + 1
	var next_p := current_phase
	
	if next_l > 3:
		next_l = 1
		next_p += 1
		
	var next_path = "res://data/Levels/level_%d-%d.tres" % [next_p, next_l]
	
	if ResourceLoader.exists(next_path):
		var loaded_level = load(next_path) as LevelData
		if loaded_level:
			set_next_level(loaded_level)
			print("Progression Saved: Next target route updated to ", next_path)
	else:
		print("Congratulations! You've cleared all available levels in this version.")

## Overriding set_next_level to cleanly bind your LevelData layout structure variables
func set_next_level(level_data: LevelData):
	next_level_resource = level_data
	current_phase = level_data.phase_number
	current_level = level_data.level_number
