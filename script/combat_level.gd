extends Node2D
class_name CombatLevel

@onready var upper_bg = $UpperBackground
@onready var battle_manager = $BattleManager

var current_level_data: LevelData

func _ready() -> void:
	print("OH YOURE IN REAL GAME!")
	await get_tree().process_frame
	var deck = $PlayerInterface/UI/Deck
	print("Deck visible:", deck.visible)
	print("Deck process:", deck.process_mode)
	if deck is Control:
		print("Mouse filter:", deck.mouse_filter)
	if not current_level_data and PlayerProfile.next_level_resource:
		current_level_data = PlayerProfile.next_level_resource
	
	if current_level_data:
		load_level_config(current_level_data)
	else:
		print("no combat config --combat level")
	
	if battle_manager and battle_manager.has_signal("battle_won"):
		battle_manager.battle_won.connect(_on_battle_manager_won)
	
	PlayerStats.player_died.connect(_on_player_dies)

func load_level_config(data):
	if data.background and upper_bg:
		upper_bg.texture = load(data.background)
	
	if battle_manager and data.enemy_data:
		battle_manager.setup_enemy(data.enemy_data)
	else:
		print("missing enemy data or battle manager -- combat level")

func _on_battle_manager_won():
	print("CombatLevel: level victory!")
	if current_level_data and current_level_data.is_boss_level:
		trigger_boss_defeat_cutscene()
	else:
		proceed_next_stage()

func proceed_next_stage():
	print("combat level: proceeding back to map area")
	PlayerProfile.current_level += 1
	var next_level_path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
	
	if ResourceLoader.exists(next_level_path):
		PlayerProfile.next_level_resource = load(next_level_path)
		if typeof(SceneTransition) != TYPE_NIL and SceneTransition.has_method("change_scene"):
			SceneTransition.change_scene(preload("res://scenes/levels/Level1.tscn"))
		else:
			print("scene transition not working -- combat level")
			get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")
	else:
		print("next level resources missing -- combat level")
		SceneTransition.change_scene(preload("res://scenes/menus/map.tscn"))

func process_chapter_scoring_and_unlock():
	print("Processing score -- combat level")
	
	var turns = PlayerProfile.run_turns
	var damage = PlayerProfile.run_damage_taken
	var total_score = clamp(10000 - (turns * 100) - (damage * 50), 0, 10000)
	
	var final_rank = "C"
	var coin_reward = 50 
	
	if total_score > 8500: 
		final_rank = "S"
		coin_reward = 500 # pwede ra ni e change to wtvr fits
	elif total_score > 7000: 
		final_rank = "A"
		coin_reward = 300
	elif total_score > 5000: 
		final_rank = "B"
		coin_reward = 150
	
	print("Final Score: ", total_score, " | Rank: ", final_rank, " | Coins Earned: ", coin_reward)
	
	PlayerProfile.add_coins(coin_reward)
	
	var chapter_key = "chapter_" + str(PlayerProfile.current_phase)
	PlayerProfile.high_scores[chapter_key] = {"rank": final_rank, "score": total_score}
	
	if PlayerProfile.current_phase == PlayerProfile.max_unlocked_chapters:
		PlayerProfile.max_unlocked_chapters += 1
	
	if typeof(Talo) != TYPE_NIL:
		Talo.leaderboards.post_score(chapter_key, total_score)
	
	SaveManager.save_game()
	
	#to-do: make score scene that displays their stats

func trigger_boss_defeat_cutscene():
	if current_level_data and not current_level_data.post_boss_cutscene.is_empty():
		print('launching cut scene')
		get_tree().change_scene_to_file(current_level_data.post_boss_cutscene)
	else:
		proceed_next_stage()

func _on_player_dies():	
	var turn_manager = get_node_or_null("PlayerInterface/GameManagers/TurnManager")
	if turn_manager:
		turn_manager.is_busy = true
	var combat_arena = get_node_or_null("CombatArena")
	if combat_arena:
		var player_node = combat_arena.get_node_or_null("Player")
		if player_node and player_node.has_method("play_death_animation"):
			# Execution halts here until the death animation completes exactly once
			await player_node.play_death_animation()
	
	var end_screen_path = "res://scenes/story/gameover.tscn" 
	var end_screen = load(end_screen_path).instantiate()
	get_tree().root.add_child(end_screen)
	await end_screen.finished
	SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
