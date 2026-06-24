extends Node2D
signal turn_changed(new_state: GameEnums.TurnState)

var current_state: GameEnums.TurnState = GameEnums.TurnState.START_TURN
var is_busy: bool = false

@onready var deck_manager = $"../DeckManager"

func _ready() -> void:
	# Small delay to let the scene tree finish initializing
	await get_tree().process_frame 
	start_game()

func start_game():
	print("--- Game Started: Waiting for player to draw ---")
	is_busy = false # Input is unlocked
	change_state(GameEnums.TurnState.DRAW_PHASE)
	# NOTE: We do NOT call start_player_turn() here!

func end_player_turn():
	change_state(GameEnums.TurnState.ENEMY_TURN)
	print("ENEMY TURN: Player is locked out for 5 seconds.")
	
	await get_tree().create_timer(1.0).timeout 
	
	# After 30s, the state goes back to Player Action (no need to click draw again!)
	start_player_turn()

func start_player_turn():
	if get_node_or_null("../ManaManager"):
		$"../ManaManager".reset_turn_mana()
	
	# State moves to PLAYER_ACTION, gate in InputManager opens, dragging works again.
	change_state(GameEnums.TurnState.PLAYER_ACTION)

func change_state(new_state: GameEnums.TurnState):
	current_state = new_state
	turn_changed.emit(current_state)
	print("Game State Changed To: ", GameEnums.TurnState.keys()[new_state])
