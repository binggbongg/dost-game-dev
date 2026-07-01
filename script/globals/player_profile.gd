extends Node
signal profile_updated # Emitted when name, character, or rank changes
signal coins_changed(new_amount: int)

var current_phase: int = 1
var current_level: int = 1

var level_database = {
	"1-1": {
		"background": "res://assets/background/rooms/background_1-1.png",
		"enemy_resource": "res://data/EnemySet/enemy_1-1.tres"
	},
	"1-2": {
		"background": "res://assets/background/rooms/background_1-2.png",
		"enemy_resource": "res://data/EnemySet/enemy_1-2.tres"
	},
	"1-3": {
		"background": "res://assets/background/rooms/background_1-3.png",
		"enemy_resource": "res://data/BossSet/boss1.tres"
	},
	"2-1": {
		"background": "res://assets/background/rooms/background_2-1.png",
		"enemy_resource": "res://data/EnemySet/enemy_2-1.tres"
	},
	"2-2": {
		"background": "res://assets/background/rooms/background_2-2.png",
		"enemy_resource": "res://data/EnemySet/enemy_2-1.tres"
	},
	"2-3": {
		"background": "res://assets/background/rooms/background_2-3.png",
		"enemy_resource": "res://data/BossSet/boss2.tres"
	},
	"3-1" : {
		"background": "res://assets/background/rooms/background_3-1.png",
		"enemy_resource": "res://data/EnemySet/enemy_3-1.tres"
	},
	"3-2": {
		"background": "res://assets/background/rooms/background_3-2.png",
		"enemy_resource": "res://data/EnemySet/enemy_3-2.tres"
	},
	"3-3": {
		"background": "res://assets/background/rooms/background_3-1.png",
		"enemy_resource": "res://data/BossSet/boss3.tres"
	},
}

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
		
func initialize_profile(new_name: String, character_id: String):
	player_name = new_name
	selected_character = character_id
	level = 1
	experience = 0
	coins = 100
	
	tutorial_steps_completed = {
		"lounge_tour": false,
		"combat_basics": false,
		"combo_tutorial": false
	}
	is_tutorial_fight = false
	
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

# ---- level logic stuff here ----

func is_boss_level():
	return current_level == 3

func get_current_level_data():
	var key = str(current_phase) + "-" + str(current_level)
	if level_database.has(key):
		return level_database[key]
	
	print("could not find level -- from playerprofile")
	return level_database["1-1"]

func get_current_bg_path():
	return get_current_level_data().get("background", "test")

func get_current_enemy_resource():
	var path = get_current_level_data().get("enemy_resource", "")
	if path != "":
		return load(path)
	
	return load("res://data/EnemySet/enemy_1-1.tres")
