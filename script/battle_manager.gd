extends Node2D

@onready var battle_timer = $"../Timer"
@onready var combat_arena = $"../CombatArena"
@onready var turn_manager = $"../PlayerInterface/GameManagers/TurnManager"
@onready var player_hand = $"../PlayerInterface/GameManagers/PlayerHand"
@onready var card_manager = $"../PlayerInterface/GameManagers/CardManager"
@onready var end_turn = $"../PlayerInterface/UI/EndTurn"
@onready var deck_manager = $"../PlayerInterface/GameManagers/DeckManager"
@onready var combo_manager = $"../PlayerInterface/GameManagers/ComboManager"
@onready var mana_manager = $"../PlayerInterface/GameManagers/ManaManager"

# angela ay ni hilabti tanan

func _ready() -> void:
	if turn_manager:
		turn_manager.turn_changed.connect(_on_turned_state_changed)
		print("battle manager connected to turn manager")
	
	if end_turn:
		end_turn.end_turn_pressed.connect(_on_end_turn_clicked)

func _on_end_turn_clicked():
	if turn_manager.is_busy:
		return
	
	turn_manager.end_player_turn()

func _on_turned_state_changed(new_state: GameEnums.TurnState):
	match new_state:
		GameEnums.TurnState.ENEMY_TURN:
			print("enemy turn")
			if combo_manager:
				var active_cards = combo_manager.get_cards_in_slots()
				for card in active_cards:
					if card_manager:
						card_manager.return_to_hand(card)
			
			await get_tree().process_frame
			await execute_enemy_turn()
			turn_manager.start_player_turn()
		GameEnums.TurnState.PLAYER_ACTION:
			print("player turn")
			
			if turn_manager:
				turn_manager.is_busy = false
			
			if mana_manager:
				mana_manager.reset_turn_mana()
			
			if player_hand:
				player_hand.replenish_hand()
			
			await get_tree().process_frame
			if card_manager:
				card_manager.refresh_hand_interaction()


func execute_enemy_turn():
	battle_timer.start(1.0)
	await battle_timer.timeout
	
	if combat_arena and combat_arena.has_method("get_enemy"):
		var enemy = combat_arena.get_enemy()
		enemy.execute_intent()
	else:
		print("execute intent method did not work or did not find enemy -- from battlemanager")
	
	battle_timer.start(0.5)
	await battle_timer.timeout
