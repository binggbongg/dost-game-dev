extends Node2D
signal turn_changed(new_state: GameEnums.TurnState)

var current_state: GameEnums.TurnState = GameEnums.TurnState.START_TURN
var is_busy: bool = false

@onready var deck_manager = $"../DeckManager"
@export var auto_start := true
func _ready():
	await get_tree().process_frame
	if auto_start:
		start_game()

func start_game():
	print("--- Game Started: Waiting for player to draw ---")
	is_busy = false # Input is unlocked
	change_state(GameEnums.TurnState.DRAW_PHASE)
	# NOTE: We do NOT call start_player_turn() here!

func end_player_turn():
	is_busy = true
	change_state(GameEnums.TurnState.ENEMY_TURN)
	print("ENEMY TURN: Player is locked out for 5 seconds.")
	

func start_player_turn():
	print("TurnManager: New turn. Mana persists from last turn.")
	
	# REMOVED: get_node("../ManaManager").reset_turn_mana()
	
	is_busy = false
	change_state(GameEnums.TurnState.PLAYER_ACTION)
func change_state(new_state: GameEnums.TurnState):
	current_state = new_state
	turn_changed.emit(current_state)
	print("Game State Changed To: ", GameEnums.TurnState.keys()[new_state])
