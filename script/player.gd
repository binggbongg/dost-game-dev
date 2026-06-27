extends Node2D

var current_armor: int = 0

func _ready() -> void:
	update_ui()

func update_ui():
	pass

func take_damage(amount: int):
	print("player hit")
	
	if current_armor > 0:
		if amount <= current_armor:
			current_armor -= amount
			amount = 0
		else:
			amount -= current_armor
			current_armor = 0
	
	PlayerStats.take_damage(amount)
	update_ui()
	
	if PlayerStats.current_health <= 0:
		print("Game over. player ded")

func add_armor(amount: int):
	current_armor += amount
	update_ui()

func reset_armor(amount: int):
	current_armor = 0
	update_ui()
