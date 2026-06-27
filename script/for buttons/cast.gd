extends Node2D

@onready var combo_manager = get_node("../../GameManagers/ComboManager")
@onready var turn_manager = get_node("../../GameManagers/TurnManager")
@onready var sprite = $Sprite2D # Make sure your sprite is named this
@onready var mana_manager: Node2D = $"../../GameManagers/ManaManager"
@onready var player_hand: Node2D = $"../../GameManagers/PlayerHand"
@onready var card_manager: Node2D = $"../../GameManagers/CardManager"

var is_disabled = true

func _process(_delta):
	var can_cast = combo_manager.validate_cast()
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if can_cast and is_player_turn:
		is_disabled = false
		self.modulate = Color(1, 1, 1, 1) # Normal color for the whole node
	else:
		is_disabled = true
		self.modulate = Color(0.3, 0.3, 0.3, 0.7) # Grayed out
		

func on_click():
	if is_disabled or turn_manager.is_busy: return
	turn_manager.is_busy = true
	
	var active_cards = combo_manager.get_cards_in_slots()
	
	# 1. Spend Mana first
	for card in active_cards:
		mana_manager.spend_mana(card.card_cost)
	
	# 2. Logic to "un-occupy" the slots physically and logically
	var slots_folder = get_node("../../Slots")
	for slot in slots_folder.get_children():
		if "card_in_slot" in slot: slot.card_in_slot = false

	# 3. Mark cards as gone so ComboManager ignores them immediately
	for card in active_cards:
		card.location = GameEnums.Location.DECK # Move out of HAND/SLOT
		card.queue_free()
	
	# 4. REPLENISH THE HAND FIRST
	# This adds the 3 new cards to the hand array
	#player_hand.replenish_hand()
	
	# 5. WAIT A SPLIT SECOND
	# This lets Godot finish the queue_free and replenishment
	await get_tree().process_frame 
	
	# 6. NOW REFRESH EVERYTHING
	# Now the slots are empty and hand is full, so all cards turn white
	card_manager.refresh_hand_interaction()
	
	# 7. End turn
	#await get_tree().create_timer(1.0).timeout
	#turn_manager.end_player_turn()
	turn_manager.is_busy = false
