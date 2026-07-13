extends TextureButton
@onready var end_turn_2: AnimatedSprite2D = $EndTurn2

@onready var combo_manager = get_node("../../GameManagers/ComboManager")
@onready var turn_manager = get_node("../../GameManagers/TurnManager")
@onready var mana_manager = get_node("../../GameManagers/ManaManager")
@onready var card_manager = get_node("../../GameManagers/CardManager")
@onready var combat_arena = get_tree().current_scene.get_node("CombatArena")

func _ready() -> void:
	self.pressed.connect(_on_pressed)

## Godot built-in processing function to update button interactive availability
func _process(_delta: float) -> void:
	update_button_state()

func update_button_state() -> void:
	if not combo_manager or not turn_manager: 
		return
	
	var can_cast = combo_manager.validate_cast()
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if can_cast and is_player_turn and not turn_manager.is_busy:
		self.disabled = false
		end_turn_2.modulate = Color(1, 1, 1, 1)
	else:
		self.disabled = true
		end_turn_2.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _on_pressed():
	if not combo_manager or not turn_manager or turn_manager.is_busy:
		return
		
	# ─── EXTRA SAFETY GATEKEEPER CHECK ───
	if not combo_manager.validate_cast():
		print("Cast Blocked: Current layout is not a valid combo pattern!")
		return
		
	print("Cast button pressed")
	var active_cards = combo_manager.get_cards_in_slots()
	print("Cards in slots: ", active_cards.size())
	
	if active_cards.is_empty():
		return
		
	if active_cards.size() == 1:
		print(active_cards[0].card_data)
		if active_cards[0].card_data is SpecialCardData:
			print("SPECIAL CARD DETECTED")
			cast_special(active_cards[0])
			return
			
	print("NORMAL CAST")
	cast_normal(active_cards)
	
func cast_normal(active_cards):
	if turn_manager.is_busy: return
	turn_manager.is_busy = true
	
	for card in active_cards:
		mana_manager.spend_mana(card.card_cost)
		
	var combo_output = combo_manager.calculate_combo_output(active_cards)
	
	var player_node = null
	if combat_arena:
		player_node = combat_arena.get_node_or_null("Player")
		if player_node and player_node.has_method("start_attack_loop"):
			player_node.start_attack_loop()

	# ─── ANIMATION SEQUENCE RUNS FIRST ───
	var sprite_anim_node = get_node_or_null("../../SpriteAnmation")
	if sprite_anim_node and sprite_anim_node.has_method("play_cast_sequence"):
		await sprite_anim_node.play_cast_sequence(active_cards)

	if player_node and player_node.has_method("stop_attack_loop"):
		combat_arena.play_player_magic()
		player_node.stop_attack_loop()
	
	# 🌟 FIX 1: Locate BattleManager reliably using the scene tree root
	var battle_mgr = null
	if get_tree().current_scene:
		battle_mgr = get_tree().current_scene.get_node_or_null("BattleManager")

	# 🌟 FIX 2: INJECT SCORE MID-BATTLE (Before applying lethal damage ends the match)
	if battle_mgr and battle_mgr.has_method("process_cast_score_injection"):
		print("Cast Button: Injecting normal combo cards into score tracker...")
		battle_mgr.process_cast_score_injection(active_cards)

	# ─── DAMAGE IS APPLIED AFTER ANIMATION FINISHES ───
	if combo_output.damage > 0:
		if combat_arena and combat_arena.has_method("get_enemy"):
			var enemy = combat_arena.get_enemy()
			if enemy and enemy.has_method("take_damage"):
				enemy.take_damage(combo_output.damage)
				if battle_mgr and battle_mgr.has_method("display_action_message"):
					battle_mgr.display_action_message("Unleashed a combo for %d damage!" % combo_output.damage)
			else:
				print("Cast Error: Active enemy node is invalid or missing take_damage()!")
		else:
			print("Cast Error: CombatArena script helper method is missing!")
	
	if combo_output.healing > 0:
		PlayerStats.heal_player(combo_output.healing)
		if battle_mgr and battle_mgr.has_method("display_action_message"):
			battle_mgr.display_action_message("Cast restorative magic for %d health!" % combo_output.healing)

	var slots_folder = get_node("../../Slots")
	if slots_folder:
		for slot in slots_folder.get_children():
			if "card_in_slot" in slot:
				slot.card_in_slot = false
	
	for card in active_cards:
		if "state" in card:
			card.state = GameEnums.CardState.PLAYED
		
		card.location = GameEnums.Location.DECK
		card.queue_free()
	
	await get_tree().process_frame
	if card_manager:
		card_manager.refresh_hand_interaction()
	print("CASTING normal")
	turn_manager.is_busy = false

func cast_special(_card):
	print("Entered cast_special()")
	if turn_manager.is_busy:
		print("Busy")
		return
	turn_manager.is_busy = true
	print("About to emit signal")
	BattleEvents.special_cast_requested.emit()
	print("Signal emitted")
