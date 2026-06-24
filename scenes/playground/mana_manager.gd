
extends Node2D

signal mana_changed(current_mana: int)

var max_mana: int = 100 
var current_mana: int = 100 # Change this from 0 to max_mana

func _ready():
	# Ensure mana is full when the game first starts
	current_mana = max_mana
	mana_changed.emit(current_mana)

# This is the missing function!
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
	
