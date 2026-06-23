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
	is_busy = false # Para clickable gihapon agng deck sa start
	
	# We start in DRAW_PHASE. This tells the InputManager that the 
	# next deck click should be the initial draw, not a shuffle.
	change_state(GameEnums.TurnState.DRAW_PHASE)

# Ensure start_player_turn only sets PLAYER_ACTION
func start_player_turn():
	if get_node_or_null("../ManaManager"):
		$"../ManaManager".reset_turn_mana()
	
	change_state(GameEnums.TurnState.PLAYER_ACTION)

func end_player_turn():
	# If we are already in the end turn process, don't do it again
	if current_state == GameEnums.TurnState.ENEMY_TURN or current_state == GameEnums.TurnState.END_TURN:
		return
	print("--- Ending Player Turn ---")
	change_state(GameEnums.TurnState.END_TURN)
	change_state(GameEnums.TurnState.ENEMY_TURN)
	
	# Simulate Enemy Turn (30 seconds) which is max time per turn.
	await get_tree().create_timer(30.0).timeout 
	
	print("--- Enemy Phase Over ---")
	start_player_turn()

func change_state(new_state: GameEnums.TurnState):
	current_state = new_state
	turn_changed.emit(current_state)
	print("Game State Changed To: ", GameEnums.TurnState.keys()[new_state])
	#  No timers or start_player_turn calls should be here purely changing of states
