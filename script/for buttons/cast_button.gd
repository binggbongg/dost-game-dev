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
	if turn_manager.is_busy: return
	turn_manager.is_busy = true
	
	var active_cards = combo_manager.get_cards_in_slots()	
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
	
	turn_manager.is_busy = false
