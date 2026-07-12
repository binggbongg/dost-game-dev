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
	var chapter = PlayerProfile.current_phase
	var extension = ".mp3" if chapter == 2 else ".wav"
	var bgm_path = "res://data/SoundData/bgm/level/chapter_%d%s" % [chapter, extension]
	
	if typeof(AudioManager) != TYPE_NIL:
		AudioManager.play_sound_from_path(bgm_path, true)
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
	
	# Freeze turns, inputs, and match timers smoothly
	if battle_manager and battle_manager.has_method("halt_battle_processing"):
		battle_manager.halt_battle_processing()
		
	var calculated_score = await process_chapter_scoring_and_unlock()
	prepare_next_progression_target()

	# Dynamic local instantiation using the secure preload variable
	if victory_screen_scene:
		print("CombatLevel: Instantiating victory interface overlay layer...")
		var victory_instance = victory_screen_scene.instantiate()
		victory_instance.name = "VictoryScreenNode"
		
		var ui_parent = get_node_or_null("PlayerInterface")
		if ui_parent:
			ui_parent.add_child(victory_instance)
		else:
			add_child(victory_instance)
		
		var current_chapter_key = "chapter_" + str(PlayerProfile.current_phase)
		var saved_record = PlayerProfile.high_scores.get(current_chapter_key, {"rank": "C"})
		var final_calculated_rank: String = saved_record.get("rank", "C")
		
		victory_instance.initialize_victory_rewards(current_level_data, calculated_score, final_calculated_rank)
		PlayerProfile.reset_run_counter()
	else:
		print("CRITICAL: victory_screen_scene file target asset path is invalid or missing!")


func prepare_next_progression_target():
	PlayerProfile.advance_to_next_level()
	if PlayerProfile.current_level == 1:
		PlayerProfile.pending_scene = "res://scenes/menus/lounge.tscn"
	else:
		PlayerProfile.pending_scene = "res://scenes/levels/Level1.tscn"

func _on_battle_manager_won():
	print("CombatLevel: level victory!")
	if current_level_data and current_level_data.is_boss_level:
		trigger_boss_defeat_cutscene()
	else:
		proceed_next_stage()
		
func proceed_next_stage():
	print("combat level: proceeding to next stage")
	# Instead of re-calculating everything here, use the pending_scene we just set
	if typeof(SceneTransition) != TYPE_NIL and SceneTransition.has_method("change_scene_path"):
		SceneTransition.change_scene_path(PlayerProfile.pending_scene)
	else:
		get_tree().change_scene_to_file(PlayerProfile.pending_scene)
func process_chapter_scoring_and_unlock() -> int:
	var turns = PlayerProfile.run_turns
	var combos_played = PlayerProfile.run_combos_played
	
	# Base score build from your card selection patterns matching casting triggers
	var gameplay_base = match_combo_bonus_points + (combos_played * 250)
	
	# Turn efficiency modifier: fewer turns keeps this multiplier closer to 1.0
	var turn_efficiency = clamp(1.0 - (turns * 0.02), 0.2, 1.0)
	
	var raw_total = gameplay_base * match_score_multipler * turn_efficiency
	var final_calculated_score: int = int(max(0, raw_total))
	
	print("--- ROUND METRICS SUMMARY ---")
	print("Run Turns Taken: ", turns)
	print("Total Card Combos Played: ", combos_played)
	print("Post-Cast Accumulated Score Points: ", match_combo_bonus_points)
	print("Final Balanced Victory Score: ", final_calculated_score)
	
	var final_rank := "C"
	if final_calculated_score >= 2000 and turns <= 10:
		final_rank = "S"
	# A Rank: Solid score output OR decent efficiency combo
	elif final_calculated_score >= 1000 or (final_calculated_score >= 900 and turns <= 13):
		final_rank = "A"
	# B Rank: Average score tier
	elif final_calculated_score >= 700:
		final_rank = "B"
	# Fallback (Under 1200 points) results in a C rank
	else:
		final_rank = "C"
	
	var bonus_packs_earned := 0
	match final_rank:
		"S": bonus_packs_earned = 3 # Premium reward for flawless play
		"A": bonus_packs_earned = 2
		"B": bonus_packs_earned = 1
		"C": bonus_packs_earned = 0
	
	var chapter_key = "chapter_" + str(PlayerProfile.current_phase)
	PlayerProfile.high_scores[chapter_key] = {"rank": final_rank, "score": final_calculated_score}
	
	if typeof(Talo) != TYPE_NIL:
		await Talo.leaderboards.add_entry(chapter_key, final_calculated_score, {
			"rank": str(final_rank)
		})
	
	SaveManager.save_game()
	return final_calculated_score

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
			await player_node.play_death_animation()
	
	PlayerProfile.current_level = 1
	var path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
	if ResourceLoader.exists(path):
		PlayerProfile.set_next_level(load(path))
	
	var end_screen_path = "res://scenes/story/gameover.tscn" 
	var end_screen = load(end_screen_path).instantiate()
	get_tree().root.add_child(end_screen)
	await end_screen.finished
	SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")

func evaluate_combo_scoring(active_cards: Array, matched_recipe: ComboRecipe):
	match_combo_bonus_points += active_cards.size() * 100
	
	if matched_recipe:
		PlayerProfile.run_combos_played += 1
		var recipe_size = matched_recipe.elements.size()
		if recipe_size == 2:
			print("2-card combo bonus")
			match_combo_bonus_points += 250
		elif recipe_size == 3:
			print("3-card combo bonus!")
			match_combo_bonus_points += 400
			match_score_multipler += 0.2
	
	print("Current Score (combatlevel): ", str(match_combo_bonus_points))

#will use this to test cutscenes and post levels stuff
#func _unhandled_input(event):
	# Press 'W' to instantly win the level and advance
	#if event is InputEventKey and event.pressed and event.keycode == KEY_W:
		#print("DEBUG: Instant Win Triggered")
		#_on_enemy_defeated()
