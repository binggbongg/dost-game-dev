extends Node2D

@export var behavior_data: EnemyBehavior

@onready var animated_sprite = $AnimatedSprite2D

var current_health: int
var current_turns: int = 0
var chosen_intent: EnemyMove

func _ready() -> void:
	
	if not behavior_data:
		behavior_data = load("res://data/EnemySet1/enemy_1.tres")
	
	if behavior_data:
		setup_enemy()
	else:
		print("enemy has no behavior data resource file")
		return

func setup_enemy():
	current_health = behavior_data.max_health
	choose_next_intent()

func choose_next_intent():
	current_turns += 1
	if behavior_data.regular_moves.size() > 0:
		chosen_intent = roll_weighted_regular_moves()
		display_chosen_intent()

func roll_weighted_regular_moves() -> EnemyMove:
	var moves_pool = behavior_data.regular_moves
	var roll = randf()
	var cumulative_chance = 0.0
	
	for move in moves_pool:
		cumulative_chance += move.chances
		if roll <= cumulative_chance:
			return move
	
	return moves_pool[0]

func display_chosen_intent():
	print(chosen_intent.name)

func execute_intent():
	if not chosen_intent:
		print("did not choose any type of moves")
		return
	
	match chosen_intent.type:
		GameEnums.EnemyMoveType.ATTACK:
			print("enemy attacked")
		GameEnums.EnemyMoveType.DEFENSE:
			print("enemy defended")
		GameEnums.EnemyMoveType.SKILL:
			print("enemy used skill")
		GameEnums.EnemyMoveType.BURST:
			print("enemy used burst")
	
	choose_next_intent()
