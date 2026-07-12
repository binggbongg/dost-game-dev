extends Node2D
class_name CombatLevel

@onready var upper_bg = $UpperBackground
@onready var battle_manager = $BattleManager
@onready var enemy = $"CombatArena/Enemy"

@export var victory_screen_scene: PackedScene

var current_level_data: LevelData
var match_combo_bonus_points: int = 0
var match_score_multipler: float = 1.0

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
	
	if is_instance_valid(enemy) and enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_defeated)

func load_level_config(data):
	if data.background and upper_bg:
		upper_bg.texture = load(data.background)
	
	if battle_manager and data.enemy_data:
		battle_manager.setup_enemy(data.enemy_data)
	else:
		print("missing enemy data or battle manager -- combat level")

func _on_enemy_defeated():
	print("CombatLevel: Enemy defeated signal caught directly!")
	
	if battle_manager and battle_manager.has_method("halt_battle_processing"):
		battle_manager.halt_battle_processing()
	
	if is_instance_valid(enemy):
		enemy.visible = false
	
	var stage_score = calculate_stage_score()
	var chapter_key = "chapter_" + str(PlayerProfile.current_phase)
	if not PlayerProfile.high_scores.has(chapter_key):
		PlayerProfile.high_scores[chapter_key] = {"score": 0, "rank": "C"}
		
	var total_chapter_score = PlayerProfile.high_scores[chapter_key].get("score", 0) + stage_score
	var final_calculated_rank = determine_overall_rank(total_chapter_score, PlayerProfile.run_turns)
	
	PlayerProfile.high_scores[chapter_key] = {"rank": final_calculated_rank, "score": total_chapter_score}
	if current_level_data and current_level_data.is_boss_level:
		if typeof(Talo) != TYPE_NIL:
			await Talo.leaderboards.add_entry(chapter_key, total_chapter_score, {
				"rank": str(final_calculated_rank)
			})
		SaveManager.save_game()
		
		# Show Victory Screen Screen Overlay now that the whole run is complete
		if victory_screen_scene:
			var victory_instance = victory_screen_scene.instantiate()
			victory_instance.name = "VictoryScreenNode"
			get_tree().root.add_child(victory_instance) # Safe global viewport overlay[cite: 11]
			victory_instance.initialize_victory_rewards(current_level_data, total_chapter_score, final_calculated_rank)
			PlayerProfile.reset_run_counter()
	else:
		# Just regular level completion, move forward cleanly
		proceed_next_stage()

func prepare_next_progression_target():
	PlayerProfile.current_level += 1
	var next_level_path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
	
	if ResourceLoader.exists(next_level_path):
		PlayerProfile.next_level_resource = load(next_level_path)
		# Save path destination so the DeckBuilder knows what level to boot back into!
		PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"
	else:
		# No standard level left; next step defaults toward lounge map structures
		PlayerProfile.pending_scene = "res://scenes/menus/map.tscn"

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

func calculate_stage_score() -> int:
	var combos_played = PlayerProfile.run_combos_played # Grab combos from this fight[cite: 11]
	var gameplay_base = match_combo_bonus_points + (combos_played * 250)
	
	# Efficiency based on a reasonable single-match turn counter scale (e.g., max 15 turns)
	var turn_efficiency = clamp(1.0 - (PlayerProfile.run_turns * 0.02), 0.2, 1.0)
	
	var raw_total = gameplay_base * match_score_multipler * turn_efficiency
	return int(max(0, raw_total))


func determine_overall_rank(total_score: int, total_turns: int) -> String:
	# S Rank across 3 levels: Excellent combos, averaging ~10 turns per map fight (Total 30)
	if total_score >= 5000 and total_turns <= 30:
		return "S"
	elif total_score >= 3500 or (total_score >= 3000 and total_turns <= 38):
		return "A"
	elif total_score >= 2000:
		return "B"
	return "C"

func trigger_boss_defeat_cutscene():
	if current_level_data and not current_level_data.post_boss_cutscene.is_empty():
		print('launching cut scene')
		SceneTransition.change_scene(current_level_data.post_boss_cutscene)
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

func evaluate_combo_scoring(active_cards: Array, matched_recipe: ComboRecipe):
	match_combo_bonus_points += active_cards.size() * 50
	
	if matched_recipe:
		PlayerProfile.run_combos_played += 1
		var recipe_size = matched_recipe.elements.size()
		if recipe_size == 2:
			print("2-card combo bonus")
			match_combo_bonus_points += 250
		elif recipe_size == 3:
			print("3-card combo bonus!")
			match_combo_bonus_points += 300
			match_score_multipler += 0.2
	
	print("Current Score (combatlevel): ", str(match_combo_bonus_points))
