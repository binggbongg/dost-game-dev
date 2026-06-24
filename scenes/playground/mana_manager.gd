extends Node2D

signal mana_changed(current_mana: int)

var max_mana: int = 100 # Starting mana
var current_mana: int = 100

func reset_turn_mana():
	# Standard card game: max mana increases by 1 each turn (cap at 10)
	# max_mana = clampi(max_mana + 1, 1, 10) 
	current_mana = max_mana
	mana_changed.emit(current_mana)

func spend_mana(amount: int) -> bool:
	if current_mana >= amount:
		print("Current mana before " + str(current_mana))
		current_mana -= amount
		print("Current mana after " + str(current_mana))
		mana_changed.emit(current_mana)
	
		return true
	return false

func can_afford(amount: int) -> bool:
	return current_mana >= amount
