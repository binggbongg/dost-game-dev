extends Node2D

@onready var battle_timer = $"../Timer"
@onready var end_cast_button = $"../Button"
@onready var combat_arena = $"../CombatArena"

func _ready() -> void:
	pass

func _on_button_pressed() -> void:
	print("player turn ended")
	end_cast_button.disabled = true
	await execute_enemy_turn()
	start_player_turn()

func execute_enemy_turn():
	print("enemy turn started")
	battle_timer.start(1.0)
	await battle_timer.timeout
	
	if combat_arena and combat_arena.has_node("Enemy1"):
		var enemy = combat_arena.get_node("Enemy1")
		enemy.execute_intent()
	else:
		print("execute intent method did not work")
	
	battle_timer.start(0.5)
	await battle_timer.timeout

func start_player_turn():
	print("player turn begin")
	end_cast_button.disabled = false
