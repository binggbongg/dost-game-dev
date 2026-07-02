extends Node
signal profile_updated # Emitted when name, character, or rank changes
signal coins_changed(new_amount: int)

var is_profile_initialized: bool = false

var current_phase: int = 1
var current_level: int = 1
var next_level_resource: LevelData = null

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
	"combat_basics": false,
	"combo_tutorial": false
}

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
		"combat_basics": false,
		"combo_tutorial": false
	}
	
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

# -- debugging purposes
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		add_coins(200)
