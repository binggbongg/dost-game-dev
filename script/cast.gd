extends Node2D

@onready var combo_manager = get_node("/root/Playground/GameManagers/ComboManager")
@onready var turn_manager = get_node("/root/Playground/GameManagers/TurnManager")
@onready var sprite = $Sprite2D # Make sure your sprite is named this

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
	
	var active_cards = combo_manager.get_cards_in_slots()
	print("Executing Cast with ", active_cards.size(), " cards!")
	
	# Logic to discard cards and deal damage (from previous step)
	for card in active_cards:
		card.queue_free()
	
	# Reset slot states
	var slots = get_node("/root/Playground/Slots")
	for slot in slots.get_children():
		if "card_in_slot" in slot: slot.card_in_slot = false

	turn_manager.end_player_turn()
