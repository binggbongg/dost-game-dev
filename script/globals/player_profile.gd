extends Node
signal profile_updated # Emitted when name, character, or rank changes
signal coins_changed(new_amount: int)

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

var level: int = 1
var experience: int = 0
var coins: int = 100:
	set(value):
		coins = value
		coins_changed.emit(coins) 
		
# Use this when the player first creates their account or starts a new game
func initialize_profile(new_name: String, character_id: String):
	player_name = new_name
	selected_character = character_id
	level = 1
	experience = 0
	coins = 100
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
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		add_coins(200)
