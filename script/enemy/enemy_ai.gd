extends Node2D

# angela ay ni hilabta
@export var behavior_data: EnemyBehavior

@onready var animated_sprite = $AnimatedSprite2D

var current_health: int
var current_turns: int = 0
var chosen_intent: EnemyMove

var special_cooldowns: Dictionary = {}

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
	if behavior_data.enemy_sprite and animated_sprite:
		animated_sprite.sprite_frames = behavior_data.enemy_sprite
		animated_sprite.play("default")
	
	choose_next_intent()

func choose_next_intent():
	current_turns += 1
	tick_cooldowns()
	
	var pool_roll = randf()
	if pool_roll <= 0.7:
		if behavior_data.regular_moves.size() > 0:
			chosen_intent = roll_weighted_moves(behavior_data.regular_moves)
	else:
		if behavior_data.special_moves.size() > 0:
			chosen_intent = get_special_moves()

func get_special_moves():
	var valid_specials = get_valid_special_move()
	
	if valid_specials.size() > 0:
		return roll_weighted_moves(valid_specials)
	
	print("no special moves available. enemy goes to regular moves")
	if behavior_data.regular_moves.size() > 0:
		return roll_weighted_moves(behavior_data.regular_moves)
	
	return null 

func get_valid_special_move():
	var valid_list: Array[EnemyMove] = []
	
	for move in behavior_data.special_moves:
		if special_cooldowns.get(move.name, 0) > 0:
			continue
		if move.type == GameEnums.EnemyMoveType.BURST and current_turns < 5:
			continue
		valid_list.append(move)
	
	return valid_list

func roll_weighted_moves(moves_pool: Array) -> EnemyMove:
	if moves_pool.size() == 0:
		return null
	
	var roll = randf()
	var cumulative_chance = 0.0
	
	for move in moves_pool:
		cumulative_chance += move.chances
		if roll <= cumulative_chance:
			return move
	
	return moves_pool[0]

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
			trigger_cooldown(chosen_intent)
		GameEnums.EnemyMoveType.BURST:
			print("enemy used burst")
			trigger_cooldown(chosen_intent)
	
	choose_next_intent()

func trigger_cooldown(move):
	if "cooldown" in move and move.cooldown > 0:
		special_cooldowns[move.name] = move.cooldown

func tick_cooldowns():
	if special_cooldowns.size() == 0:
		return	
	
	for move_name in special_cooldowns.keys():
		if special_cooldowns[move_name] > 0:
			special_cooldowns[move_name] -= 1
