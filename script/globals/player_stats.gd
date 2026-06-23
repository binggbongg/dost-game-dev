extends Node

var max_energy: int = 5
var max_health: int = 50
var current_health: int

func reset_health():
	max_health = current_health

#func spend_energy(amount: int):
	#if current_energy >= amount:
		#current_energy -= amount
		#return true
	#
	#return false

func take_damage(amount: int):
	if current_health >= amount:
		current_health -= amount
		return true
	
	return false
