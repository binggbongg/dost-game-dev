extends Node2D

signal turn_changed(new_state: GameEnums.TurnState)

var current_state: GameEnums.TurnState = GameEnums.TurnState.START_TURN

@onready var deck_manager = $"../DeckManager"

func _ready() -> void:
	# Give the scene a moment to load, then start the first turn
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

func start_player_turn():
	change_state(GameEnums.TurnState.START_TURN)
	
	# Transition to Draw Phase
	change_state(GameEnums.TurnState.DRAW_PHASE)
	# Mana resets at start of turn (we will create ManaManager next)
	if get_node_or_null("../ManaManager"):
		$"../ManaManager".reset_turn_mana()
	
	# Transition to Player Action (This is when they can drag cards)
	change_state(GameEnums.TurnState.PLAYER_ACTION)

func end_player_turn():
	change_state(GameEnums.TurnState.END_TURN)
	# Here is where you'd trigger the enemy turn
	change_state(GameEnums.TurnState.ENEMY_TURN)
	print("Enemy is thinking...")

func change_state(new_state: GameEnums.TurnState):
	current_state = new_state
	turn_changed.emit(current_state)
	print("Game State: ", GameEnums.TurnState.keys()[new_state])
