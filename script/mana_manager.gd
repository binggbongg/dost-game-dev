extends Node2D

signal mana_changed(current_mana: int)

var max_mana: int = 12
var current_mana: int = 12

func _ready():
	if PlayerStats:
		max_mana = PlayerStats.max_mana
	else:
		max_mana = 12
		
	current_mana = max_mana
	mana_changed.emit(current_mana)

func reset_turn_mana():
	print("ManaManager: Refilling mana for the new turn.")
	current_mana = max_mana
	mana_changed.emit(current_mana)

func spend_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana)
		return true
	return false

func can_afford(amount: int) -> bool:
	return current_mana >= amount
