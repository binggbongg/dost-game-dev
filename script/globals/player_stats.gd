extends Node

signal health_changed(new_health: int)
signal player_died

var max_mana: int = 12
var max_health: int = 50
var current_health: int
var last_current_health: int = 50

@onready var health_bar:UIStatusBar

func _ready() -> void:
	current_health = max_health
	
	print("player health: ", current_health)

func reset_health():
	current_health = max_health
	last_current_health = max_health

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	PlayerProfile.run_damage_taken += amount
	health_changed.emit(current_health)
	
	print("player took ", amount, " damage. health: ", current_health)
	
	if current_health <= 0:
		print("Player has died")
		player_died.emit()
		reset_health()

func heal_player(amount):
	if amount <= 0: return
	
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)
	print("player healed")

func snapshot_level_entry_health() -> void:
	last_current_health = current_health
	print("[PROFILE] Level entry health snapshot captured: ", last_current_health)

func restore_level_entry_health() -> void:
	current_health = last_current_health
	print("[PROFILE] Restart detected. Health restored to: ", current_health)
