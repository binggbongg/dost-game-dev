extends Node2D

@export var behavior_data: EnemyBehavior
@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $EnemyHealthBar

var current_health: int
var current_turns: int = 0
var chosen_intent: EnemyMove
var special_cooldowns: Dictionary = {}
var is_defeated: bool = false

signal enemy_health_changed(new_health: int)
signal enemy_died

func initialize_from_resource(new_behavior: EnemyBehavior):
	behavior_data = new_behavior
	setup_enemy()

func setup_enemy():
	if not behavior_data: 
		print("Enemy AI Error: setup_enemy called but behavior_data is missing!")
		return
	
	current_health = behavior_data.max_health
	is_defeated = false
	if health_bar and health_bar.has_method("initialize_bar"):
		health_bar.initialize_bar(
			behavior_data.max_health,
			current_health,
			enemy_health_changed,
			0,
			0,
			enemy_health_changed
		)
	
	enemy_health_changed.emit(current_health)
	
	if behavior_data.enemy_sprite and animated_sprite:
		animated_sprite.sprite_frames = behavior_data.enemy_sprite
		animated_sprite.play("idle")
	
	choose_next_intent()

func take_damage(amount):
	if is_defeated: return
	
	current_health = max(0, current_health - amount)
	print(name, " takes ", amount, " of damage. current health: ", current_health)
	enemy_health_changed.emit(current_health)
	
	if current_health <= 0:
		is_defeated = true
		#print("enemy has been defeated")
		#enemy_died.emit()
		if animated_sprite and animated_sprite.sprite_frames.has_animation("death"):
			animated_sprite.play("death")
			await animated_sprite.animation_finished
		else:
			visible = false
		
		enemy_died.emit()
		

func choose_next_intent():
	if current_health <= 0: return
	
	current_turns += 1
	tick_cooldowns()
	
	chosen_intent = null
	var pool_roll = randf()
	
	if pool_roll <= 0.7:
		if behavior_data.regular_moves.size() > 0:
			chosen_intent = roll_weighted_moves(behavior_data.regular_moves)
	else:
		if behavior_data.special_moves.size() > 0:
			chosen_intent = get_special_moves()
	
	if not chosen_intent:
		print("CRITICAL ERROR: ", name, " could not choose ANY move! Check your .tres resource settings.")

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

# 🌟 MODIFIED: Converted to a coroutine (using async await) so it handles animation states properly
func execute_intent():
	if is_defeated:
		print("execute_intent() called on a defeated enemy, ignoring")
		return
	
	if not chosen_intent:
		print("did not choose any type of moves")
		return
	
	var anim_to_play := ""
	
	match chosen_intent.type:
		GameEnums.EnemyMoveType.ATTACK:
			print("enemy used regular attack")
			anim_to_play = "skill_1"
			if PlayerStats:
				PlayerStats.take_damage(chosen_intent.value)

		GameEnums.EnemyMoveType.SKILL:
			print("enemy used skill")
			anim_to_play = "skill_2"
			if PlayerStats:
				PlayerStats.take_damage(chosen_intent.value)
			trigger_cooldown(chosen_intent)

		GameEnums.EnemyMoveType.BURST:
			print("enemy used burst")
			anim_to_play = "burst"
			if PlayerStats:
				PlayerStats.take_damage(chosen_intent.value)
			trigger_cooldown(chosen_intent)
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_to_play):
		animated_sprite.play(anim_to_play)
		
		var combat_arena = get_parent()
		await get_tree().create_timer(1.0).timeout
		var player = combat_arena.get_player()
		if player and player.has_method("flash_red_damage"):
			player.flash_red_damage()
	else:
		print("Warning: Animation ", anim_to_play, " missing from SpriteFrames!")
		
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

func flash_red_damage():
	if is_defeated: return
	
	await get_tree().create_timer(0.75).timeout
	var original_color = animated_sprite.modulate
	var flash_tween = create_tween()
	
	animated_sprite.modulate = Color(1, 0.1, 0.1, 1)
	
	flash_tween.tween_property(animated_sprite, "modulate", original_color, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func any_signals(signals_array: Array) -> void:
	var completed = false
	var callable = func(): completed = true
	
	for sig in signals_array:
		if sig is Signal:
			sig.connect(callable, CONNECT_ONE_SHOT)
		elif sig is SceneTreeTimer:
			sig.timeout.connect(callable, CONNECT_ONE_SHOT)
			
	while not completed and is_inside_tree():
		await get_tree().process_frame
