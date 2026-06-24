extends Node2D

@onready var card_manager = get_node("../../GameManagers/CardManager")
@onready var combo_manager = get_node("../../GameManagers/ComboManager")
@onready var turn_manager = get_node("../../GameManagers/TurnManager")
@onready var sprite = $Sprite2D

var is_disabled = true

func _process(_delta):
	var has_cards = combo_manager.get_cards_in_slots().size() > 0
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if has_cards and is_player_turn:
		is_disabled = false
		self.modulate = Color(1, 1, 1, 1)
	else:
		is_disabled = true
		self.modulate = Color(0.3, 0.3, 0.3, 0.7)

func on_click():
	if is_disabled or turn_manager.is_busy: return
	
	var active_cards = combo_manager.get_cards_in_slots()
	for card in active_cards:
		card_manager.return_to_hand(card)
	
	print("Redo triggered: Cards returned to hand.")
