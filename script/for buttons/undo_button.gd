extends TextureButton

@onready var combo_manager = get_node("../../GameManagers/ComboManager")
@onready var turn_manager = get_node("../../GameManagers/TurnManager")
@onready var card_manager = get_node("../../GameManagers/CardManager")

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _process(_delta: float) -> void:
	if not combo_manager or not turn_manager: return
	
	var has_cards = combo_manager.get_cards_in_slots().size() > 0
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if has_cards and is_player_turn and not turn_manager.is_busy:
		self.disabled = false
		self_modulate = Color(1, 1, 1, 1)
	else:
		self.disabled = true
		self_modulate = Color(0.3, 0.3, 0.3, 0.8)

func _on_pressed():
	
	if turn_manager.is_busy: return
	AudioManager.play_ui_sound("click")
	var active_cards = combo_manager.get_cards_in_slots()
	if active_cards.size() > 0:
		for card in active_cards:
			if card_manager:
				card_manager.return_to_hand(card)
	else:
		BattleEvents.special_cancel_requested.emit()
