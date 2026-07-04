extends Node

signal health_changed(new_health: int)
signal player_died

var max_mana: int = 12
var max_health: int = 50
var current_health: int

@onready var health_bar:UIStatusBar

func _ready() -> void:
	current_health = max_health
	
	print("player health: ", current_health)

func reset_health():
	current_health = max_health

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	PlayerProfile.run_damage_taken += amount
	health_changed.emit(current_health)
	
	print("player took ", amount, " damage. health: ", current_health)
	
	if current_health <= 0:
		print("Player has died")
		player_died.emit()

func heal_player(amount):
	if amount <= 0: return
	
	current_health = min(max_health, current_health + max_health)
	health_changed.emit(current_health)
	print("player healed")
