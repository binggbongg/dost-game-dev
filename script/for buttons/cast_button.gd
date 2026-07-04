extends TextureButton

@onready var combo_manager = get_node("../../GameManagers/ComboManager")
@onready var turn_manager = get_node("../../GameManagers/TurnManager")
@onready var mana_manager = get_node("../../GameManagers/ManaManager")
@onready var card_manager = get_node("../../GameManagers/CardManager")
#@onready var combat_arena = get_node("../../../CombatArena")
@onready var combat_arena = get_tree().current_scene.get_node("CombatArena")

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _pressed() -> void:
	if not combo_manager or turn_manager: return
	
	var can_cast = combo_manager.validate_cast()
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if can_cast and is_player_turn and not turn_manager.is_busy:
		self.disabled = false
		self_modulate = Color(1, 1, 1, 1)
	else:
		self.disabled = true
		self_modulate = Color(0.3, 0.3, 0.3, 0.8)
func _on_pressed():
	print("Cast button pressed")
	AudioManager.play_ui_sound("click")
	if turn_manager.is_busy:
		return
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
	if combo_output.damage > 0:
		if combat_arena and combat_arena.has_method("get_enemy"):
			var enemy = combat_arena.get_enemy()
			if enemy and enemy.has_method("take_damage"):
				enemy.take_damage(combo_output.damage)
			else:
				print("Cast Error: Active enemy node is invalid or missing take_damage()!")
		else:
			print("Cast Error: CombatArena script helper method is missing!")
	
	if combat_arena:
		# Adjust the node path "Player" if your player node has a different name inside CombatArena
		var player_node = combat_arena.get_node_or_null("Player")
		if player_node and player_node.has_method("play_attack_animation"):
			player_node.play_attack_animation()

	var sprite_anim_node = get_node_or_null("../../SpriteAnmation")
	if sprite_anim_node and sprite_anim_node.has_method("play_cast_sequence"):
		await sprite_anim_node.play_cast_sequence(active_cards)

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
